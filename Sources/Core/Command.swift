/// 相対操作の向き。
public enum Direction: Sendable {
    case up
    case down
}

/// 状態を変化させる操作。
public enum Command: Equatable, Sendable {
    /// 完全 or 部分指定。両方 nil は parse 側で拒否する。
    case set(key: PitchClass?, scale: Scale?)
    case scaleStep(Direction)
    case rootStep(Direction)
}

/// 引数パースの失敗を表す明示的エラー型（process exit はしない）。
public enum ParseError: Error, Equatable, Sendable {
    /// サブコマンドが無い。
    case missingSubcommand
    /// 未知のサブコマンド。
    case unknownSubcommand(String)
    /// 未知のオプション。
    case unknownOption(String)
    /// オプションに必要な値が欠けている。
    case missingValue(option: String)
    /// 不正なキー名。
    case invalidKey(String)
    /// 不正なスケール名。
    case invalidScale(String)
    /// set に key も scale も指定が無い。
    case emptySet
    /// scale/root に向き（--up/--down）が無い、または両方指定。
    case missingDirection
    /// 同一の向きやキー等が重複・矛盾している。
    case conflictingArguments(String)
}

/// キー名 → PitchClass。シャープ/フラット両表記に対応（大文字小文字は区別しない先頭文字）。
public func parseKey(_ raw: String) -> PitchClass? {
    let table: [String: Int] = [
        "c": 0, "b#": 0,
        "c#": 1, "db": 1,
        "d": 2,
        "d#": 3, "eb": 3,
        "e": 4, "fb": 4,
        "f": 5, "e#": 5,
        "f#": 6, "gb": 6,
        "g": 7,
        "g#": 8, "ab": 8,
        "a": 9,
        "a#": 10, "bb": 10,
        "b": 11, "cb": 11,
    ]
    let normalized = raw.lowercased()
    guard let v = table[normalized] else { return nil }
    return PitchClass(v)
}

/// スケール名 → Scale。ハイフン/キャメル両表記を受ける（例: natural-minor / naturalMinor）。
public func parseScale(_ raw: String) -> Scale? {
    let table: [String: Scale] = [
        "major": .major,
        "natural-minor": .naturalMinor,
        "naturalminor": .naturalMinor,
        "minor": .naturalMinor,
        "dorian": .dorian,
        "mixolydian": .mixolydian,
        "major-pentatonic": .majorPentatonic,
        "majorpentatonic": .majorPentatonic,
        "minor-pentatonic": .minorPentatonic,
        "minorpentatonic": .minorPentatonic,
        "blues": .blues,
    ]
    return table[raw.lowercased()]
}

/// 引数列を Command へ変換する純粋関数。
///
/// サブコマンド: `set` / `scale` / `root`
/// オプション: `--key <name>` `--scale <name>` `--up` `--down`
public func parse(_ args: [String]) -> Result<Command, ParseError> {
    guard let sub = args.first else {
        return .failure(.missingSubcommand)
    }
    let rest = Array(args.dropFirst())

    switch sub {
    case "set":
        return parseSet(rest)
    case "scale":
        return parseDirectional(rest).map { .scaleStep($0) }
    case "root":
        return parseDirectional(rest).map { .rootStep($0) }
    default:
        return .failure(.unknownSubcommand(sub))
    }
}

/// `set --key C --scale major` 等。key/scale の部分指定を許す。両方欠けたら emptySet。
private func parseSet(_ args: [String]) -> Result<Command, ParseError> {
    var key: PitchClass?
    var scale: Scale?
    var i = 0
    while i < args.count {
        let token = args[i]
        switch token {
        case "--key":
            guard i + 1 < args.count else { return .failure(.missingValue(option: "--key")) }
            if key != nil { return .failure(.conflictingArguments("--key")) }
            guard let parsed = parseKey(args[i + 1]) else {
                return .failure(.invalidKey(args[i + 1]))
            }
            key = parsed
            i += 2
        case "--scale":
            guard i + 1 < args.count else { return .failure(.missingValue(option: "--scale")) }
            if scale != nil { return .failure(.conflictingArguments("--scale")) }
            guard let parsed = parseScale(args[i + 1]) else {
                return .failure(.invalidScale(args[i + 1]))
            }
            scale = parsed
            i += 2
        default:
            return .failure(.unknownOption(token))
        }
    }
    guard key != nil || scale != nil else {
        return .failure(.emptySet)
    }
    return .success(.set(key: key, scale: scale))
}

/// `--up` / `--down` のいずれか 1 つを要求する。
private func parseDirectional(_ args: [String]) -> Result<Direction, ParseError> {
    var direction: Direction?
    for token in args {
        switch token {
        case "--up":
            if direction != nil { return .failure(.conflictingArguments("--up/--down")) }
            direction = .up
        case "--down":
            if direction != nil { return .failure(.conflictingArguments("--up/--down")) }
            direction = .down
        default:
            return .failure(.unknownOption(token))
        }
    }
    guard let d = direction else {
        return .failure(.missingDirection)
    }
    return .success(d)
}
