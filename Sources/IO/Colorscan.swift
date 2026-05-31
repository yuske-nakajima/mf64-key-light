import Foundation

/// colorscan の 1 ステップ（送る note と velocity）。
public struct ColorscanStep: Equatable, Sendable {
    public let note: Int
    public let velocity: UInt8

    public init(note: Int, velocity: UInt8) {
        self.note = note
        self.velocity = velocity
    }
}

/// colorscan の設定。`--from` `--to` は両端含む昇順 range として解釈する。
public struct ColorscanConfig: Equatable, Sendable {
    public let note: Int
    public let from: UInt8
    public let to: UInt8
    public let delayMilliseconds: Int

    public init(note: Int, from: UInt8, to: UInt8, delayMilliseconds: Int) {
        self.note = note
        self.from = from
        self.to = to
        self.delayMilliseconds = delayMilliseconds
    }
}

/// 設定から送信する (note, velocity) 列を生成する純粋関数。
///
/// from <= to の昇順両端含む。from > to の場合は空列を返す。
public func colorscanSteps(_ config: ColorscanConfig) -> [ColorscanStep] {
    guard config.from <= config.to else { return [] }
    return (config.from...config.to).map { velocity in
        ColorscanStep(note: config.note, velocity: velocity)
    }
}

/// colorscan 引数のパース失敗。
public enum ColorscanParseError: Error, Equatable, Sendable {
    case missingValue(option: String)
    case invalidValue(option: String, value: String)
    case unknownOption(String)
    /// from/to が 0..127 の範囲外。
    case velocityOutOfRange(UInt8)
}

/// `colorscan [--note N] [--from A] [--to B] [--delay MS]` の引数を ColorscanConfig へ変換する。
///
/// 既定: note=Devices.colorscanDefaultNote, from=0, to=127, delay=300ms。
public func parseColorscan(_ args: [String]) -> Result<ColorscanConfig, ColorscanParseError> {
    var note = Devices.colorscanDefaultNote
    var from = 0
    var to = 127
    var delay = 300

    var i = 0
    while i < args.count {
        let token = args[i]
        func nextInt(_ option: String) -> Result<Int, ColorscanParseError> {
            guard i + 1 < args.count else { return .failure(.missingValue(option: option)) }
            guard let value = Int(args[i + 1]) else {
                return .failure(.invalidValue(option: option, value: args[i + 1]))
            }
            return .success(value)
        }

        switch token {
        case "--note":
            switch nextInt("--note") {
            case .success(let v): note = v
            case .failure(let e): return .failure(e)
            }
            i += 2
        case "--from":
            switch nextInt("--from") {
            case .success(let v): from = v
            case .failure(let e): return .failure(e)
            }
            i += 2
        case "--to":
            switch nextInt("--to") {
            case .success(let v): to = v
            case .failure(let e): return .failure(e)
            }
            i += 2
        case "--delay":
            switch nextInt("--delay") {
            case .success(let v): delay = v
            case .failure(let e): return .failure(e)
            }
            i += 2
        default:
            return .failure(.unknownOption(token))
        }
    }

    guard (0...127).contains(from) else {
        return .failure(.velocityOutOfRange(UInt8(clamping: from)))
    }
    guard (0...127).contains(to) else { return .failure(.velocityOutOfRange(UInt8(clamping: to))) }

    return .success(
        ColorscanConfig(
            note: note,
            from: UInt8(from),
            to: UInt8(to),
            delayMilliseconds: max(0, delay)
        )
    )
}
