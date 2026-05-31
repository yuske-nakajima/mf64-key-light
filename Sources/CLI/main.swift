import Core
import Foundation
import IO

/// PitchClass.value → 表示用キー名（シャープ表記）。
private let keyNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

/// 使い方を標準エラーに出す。
private func printUsage() {
    let usage = """
        usage: mf64 <subcommand> [options]

        subcommands:
          set   --key <name> | --scale <name>   キー/スケールを設定（片方だけでも可）
          scale --up | --down                   スケールを巡回方向へ 1 つ進める
          root  --up | --down                   ルートを半音上下する
          off                                   全 64 パッドを消灯（velocity 0）
          config [--channel N] [--root V] [--member V] [--outside V]
                                                MIDI チャンネル(1..16)と紫/水色/白の velocity(0..127)
                                                を設定。引数なしで現在値を表示
          colorscan [--note N] [--from A] [--to B] [--delay MS]
                                                指定 note に velocity A..B を順送りして校正
          monitor                               MF64 の入力を監視しログ出力（Ctrl-C で終了）

        config の参考値: channel=2 / 紫(root)=54 / 水色(member)=36 / 白(outside)=3

        examples:
          mf64 set --key C --scale major
          mf64 scale --up
          mf64 root --down
          mf64 off
          mf64 config
          mf64 config --channel 3 --root 50
          mf64 colorscan --from 0 --to 20 --delay 300
          mf64 monitor
        """
    FileHandle.standardError.write(Data((usage + "\n").utf8))
}

/// ParseError を人間可読なメッセージへ変換する。
private func describe(_ error: ParseError) -> String {
    switch error {
    case .missingSubcommand:
        return "サブコマンドがありません（set / scale / root / off / config / colorscan）"
    case .unknownSubcommand(let s):
        return "未知のサブコマンドです: \(s)"
    case .unknownOption(let s):
        return "未知のオプションです: \(s)"
    case .missingValue(let option):
        return "オプション \(option) に値が必要です"
    case .invalidKey(let s):
        return "不正なキー名です: \(s)"
    case .invalidScale(let s):
        return "不正なスケール名です: \(s)"
    case .emptySet:
        return "set には --key または --scale が必要です"
    case .missingDirection:
        return "--up または --down が必要です"
    case .conflictingArguments(let s):
        return "引数が重複・矛盾しています: \(s)"
    }
}

/// ConfigParseError を人間可読なメッセージへ変換する。
private func describe(_ error: ConfigParseError) -> String {
    switch error {
    case .missingValue(let option):
        return "オプション \(option) に値が必要です"
    case .invalidValue(let option, let value):
        return "オプション \(option) の値が不正です: \(value)"
    case .unknownOption(let s):
        return "未知のオプションです: \(s)"
    case .channelOutOfRange(let v):
        return "--channel は 1..16 の範囲です: \(v)"
    case .colorOutOfRange(let option, let value):
        return "\(option) は 0..127 の範囲です: \(value)"
    }
}

/// ColorscanParseError を人間可読なメッセージへ変換する。
private func describe(_ error: ColorscanParseError) -> String {
    switch error {
    case .missingValue(let option):
        return "オプション \(option) に値が必要です"
    case .invalidValue(let option, let value):
        return "オプション \(option) の値が不正です: \(value)"
    case .unknownOption(let s):
        return "未知のオプションです: \(s)"
    case .velocityOutOfRange(let v):
        return "velocity は 0..127 の範囲です: \(v)"
    }
}

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("error: " + message + "\n").utf8))
    exit(1)
}

/// dry-run（`MF64_MIDI_DRY_RUN=1`）か。実機なしでパイプライン確認に使う。
private func isDryRun() -> Bool {
    ProcessInfo.processInfo.environment["MF64_MIDI_DRY_RUN"] == "1"
}

/// 実送信用の RawMIDISender を返す。dry-run なら LoggingMIDISender。
/// 実機モードで destination 不在なら nil（呼び出し側で扱う）。
private func makeRawSender(_ settings: Settings) -> RawMIDISender? {
    if isDryRun() {
        return LoggingMIDISender(settings: settings)
    }
    return try? CoreMIDISender(settings: settings)
}

/// DB から設定を読む。失敗時は fail で終了。
private func loadSettings() -> Settings {
    do {
        return try StateStore().loadSettings()
    } catch {
        fail("設定の読み込みに失敗しました: \(error)")
    }
}

// MARK: - config（設定の表示・更新）

private func printSettings(_ settings: Settings) {
    print(
        "config: channel=\(settings.midiChannel) "
            + "紫(root)=\(settings.colorRoot) 水色(member)=\(settings.colorMember) "
            + "白(outside)=\(settings.colorOutside)"
    )
}

private func runConfig(_ rest: [String]) -> Never {
    let store = StateStore()
    let current: Settings
    do {
        current = try store.loadSettings()
    } catch {
        fail("設定の読み込みに失敗しました: \(error)")
    }

    if rest.isEmpty {
        printSettings(current)
        exit(0)
    }

    let updated: Settings
    switch parseConfig(rest, base: current) {
    case .success(let s):
        updated = s
    case .failure(let error):
        FileHandle.standardError.write(Data(("error: " + describe(error) + "\n").utf8))
        printUsage()
        exit(1)
    }

    do {
        try store.saveSettings(updated)
    } catch {
        fail("設定の保存に失敗しました: \(error)")
    }
    printSettings(updated)
    exit(0)
}

// MARK: - off / colorscan（状態遷移でない CLI 専用サブコマンド）

private func runOff() -> Never {
    let settings = loadSettings()
    guard let sender = makeRawSender(settings) else {
        fail(CoreMIDIError.destinationNotFound.description)
    }
    sender.sendAllOff(padMap: Devices.defaultPadMap)
    print("off: 全 \(Devices.padCount) パッドに velocity 0 を送信")
    exit(0)
}

private func runColorscan(_ rest: [String]) -> Never {
    let config: ColorscanConfig
    switch parseColorscan(rest) {
    case .success(let c):
        config = c
    case .failure(let error):
        FileHandle.standardError.write(Data(("error: " + describe(error) + "\n").utf8))
        printUsage()
        exit(1)
    }

    let settings = loadSettings()
    guard let sender = makeRawSender(settings) else {
        fail(CoreMIDIError.destinationNotFound.description)
    }

    let steps = colorscanSteps(config)
    let delaySeconds = Double(config.delayMilliseconds) / 1000.0
    for step in steps {
        sender.sendNoteOn(note: step.note, velocity: step.velocity)
        print("colorscan: note=\(step.note) velocity=\(step.velocity)")
        if step.velocity != config.to && delaySeconds > 0 {
            // 各色をユーザーが目視で判別できるよう間隔を空ける。
            Thread.sleep(forTimeInterval: delaySeconds)
        }
    }
    exit(0)
}

// MARK: - monitor（入力監視・デバッグ用）

private func runMonitor() -> Never {
    let monitor: CoreMIDIMonitor
    do {
        monitor = try CoreMIDIMonitor { message in
            print("\(message.description)")
        }
    } catch {
        fail("\(error)")
    }
    // monitor を保持したまま RunLoop を回す（解放されると購読が切れる）。
    _ = monitor
    FileHandle.standardError.write(Data("monitor: Midi Fighter 64 を監視中。Ctrl-C で終了\n".utf8))
    RunLoop.main.run()
    exit(0)
}

// MARK: - set / scale / root（状態遷移）

private func runStateCommand(_ command: Command) -> Never {
    let store = StateStore()

    let current: State
    do {
        current = try store.load()
    } catch {
        fail("状態の読み込みに失敗しました: \(error)")
    }

    let updated = apply(current, command)

    // 送信前に状態保存を済ませる（destination 不在でも保存は確定させる）。
    do {
        try store.save(updated)
    } catch {
        fail("状態の保存に失敗しました: \(error)")
    }

    let keyName = keyNames[updated.key.value]
    print("state: key=\(keyName) scale=\(updated.scale.rawValue)")

    let settings: Settings
    do {
        settings = try store.loadSettings()
    } catch {
        fail("設定の読み込みに失敗しました: \(error)")
    }

    let pads = layout(state: updated, padMap: Devices.defaultPadMap)

    if isDryRun() {
        LoggingMIDISender(settings: settings).send(pads, padMap: Devices.defaultPadMap)
        exit(0)
    }

    do {
        let sender = try CoreMIDISender(settings: settings)
        sender.send(pads, padMap: Devices.defaultPadMap)
        exit(0)
    } catch {
        // 状態は保存済み。送信だけ失敗したことを伝えて非0 exit。
        FileHandle.standardError.write(Data(("error: \(error)\n").utf8))
        exit(2)
    }
}

// MARK: - エントリポイント

let args = Array(CommandLine.arguments.dropFirst())

guard let sub = args.first else {
    printUsage()
    exit(1)
}

let rest = Array(args.dropFirst())

switch sub {
case "config":
    runConfig(rest)
case "off":
    runOff()
case "colorscan":
    runColorscan(rest)
case "monitor":
    runMonitor()
default:
    let command: Command
    switch parse(args) {
    case .success(let c):
        command = c
    case .failure(let error):
        FileHandle.standardError.write(Data(("error: " + describe(error) + "\n").utf8))
        printUsage()
        exit(1)
    }
    runStateCommand(command)
}
