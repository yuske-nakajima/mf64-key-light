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
          colorscan [--note N] [--from A] [--to B] [--delay MS]
                                                指定 note に velocity A..B を順送りして校正

        examples:
          mf64 set --key C --scale major
          mf64 scale --up
          mf64 root --down
          mf64 off
          mf64 colorscan --from 0 --to 20 --delay 300
        """
    FileHandle.standardError.write(Data((usage + "\n").utf8))
}

/// ParseError を人間可読なメッセージへ変換する。
private func describe(_ error: ParseError) -> String {
    switch error {
    case .missingSubcommand:
        return "サブコマンドがありません（set / scale / root / off / colorscan）"
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
private func makeRawSender() -> RawMIDISender? {
    if isDryRun() {
        return LoggingMIDISender()
    }
    return try? CoreMIDISender()
}

// MARK: - off / colorscan（状態遷移でない CLI 専用サブコマンド）

private func runOff() -> Never {
    guard let sender = makeRawSender() else {
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

    guard let sender = makeRawSender() else {
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

    let pads = layout(state: updated, padMap: Devices.defaultPadMap)

    if isDryRun() {
        LoggingMIDISender().send(pads, padMap: Devices.defaultPadMap)
        exit(0)
    }

    do {
        let sender = try CoreMIDISender()
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
case "off":
    runOff()
case "colorscan":
    runColorscan(rest)
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
