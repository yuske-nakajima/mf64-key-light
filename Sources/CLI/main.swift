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

        examples:
          mf64 set --key C --scale major
          mf64 scale --up
          mf64 root --down
        """
    FileHandle.standardError.write(Data((usage + "\n").utf8))
}

/// ParseError を人間可読なメッセージへ変換する。
private func describe(_ error: ParseError) -> String {
    switch error {
    case .missingSubcommand:
        return "サブコマンドがありません（set / scale / root）"
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

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("error: " + message + "\n").utf8))
    exit(1)
}

// MARK: - 実行

let args = Array(CommandLine.arguments.dropFirst())

guard !args.isEmpty else {
    printUsage()
    exit(1)
}

let command: Command
switch parse(args) {
case .success(let c):
    command = c
case .failure(let error):
    FileHandle.standardError.write(Data(("error: " + describe(error) + "\n").utf8))
    printUsage()
    exit(1)
}

let store = StateStore()

let current: State
do {
    current = try store.load()
} catch {
    fail("状態の読み込みに失敗しました: \(error)")
}

let updated = apply(current, command)

do {
    try store.save(updated)
} catch {
    fail("状態の保存に失敗しました: \(error)")
}

let keyName = keyNames[updated.key.value]
print("state: key=\(keyName) scale=\(updated.scale.rawValue)")

let pads = layout(state: updated, padMap: Devices.dummyPadMap)
let sender = LoggingMIDISender()
sender.send(pads, padMap: Devices.dummyPadMap)
