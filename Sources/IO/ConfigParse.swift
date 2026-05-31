/// `config` サブコマンドの引数パース失敗。
public enum ConfigParseError: Error, Equatable, Sendable {
    case missingValue(option: String)
    case invalidValue(option: String, value: String)
    case unknownOption(String)
    /// channel が 1..16 の範囲外。
    case channelOutOfRange(Int)
    /// 色 velocity が 0..127 の範囲外。
    case colorOutOfRange(option: String, value: Int)
}

/// `config [--channel N] [--root V] [--member V] [--outside V]` を base 設定へ適用する純粋関数。
///
/// 指定された項目だけを base から上書きして返す。引数なしなら base をそのまま返す。
/// 範囲外（channel 1..16 / color 0..127）・不正値はエラーを返す。
public func parseConfig(_ args: [String], base: Settings) -> Result<Settings, ConfigParseError> {
    var result = base

    var i = 0
    while i < args.count {
        let token = args[i]
        guard i + 1 < args.count else {
            return .failure(.missingValue(option: token))
        }
        let rawValue = args[i + 1]
        guard let value = Int(rawValue) else {
            return .failure(.invalidValue(option: token, value: rawValue))
        }

        switch token {
        case "--channel":
            guard (1...16).contains(value) else {
                return .failure(.channelOutOfRange(value))
            }
            result.midiChannel = value
        case "--root":
            guard (0...127).contains(value) else {
                return .failure(.colorOutOfRange(option: token, value: value))
            }
            result.colorRoot = UInt8(value)
        case "--member":
            guard (0...127).contains(value) else {
                return .failure(.colorOutOfRange(option: token, value: value))
            }
            result.colorMember = UInt8(value)
        case "--outside":
            guard (0...127).contains(value) else {
                return .failure(.colorOutOfRange(option: token, value: value))
            }
            result.colorOutside = UInt8(value)
        default:
            return .failure(.unknownOption(token))
        }
        i += 2
    }

    return .success(result)
}
