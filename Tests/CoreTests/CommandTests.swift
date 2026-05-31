import Testing

@testable import Core

@Suite("Command")
struct CommandTests {
    private func ok(_ args: [String]) -> Command? {
        if case .success(let c) = parse(args) { return c }
        return nil
    }

    private func err(_ args: [String]) -> ParseError? {
        if case .failure(let e) = parse(args) { return e }
        return nil
    }

    // MARK: - キー名 / スケール名

    /// キー名 → PitchClass（シャープ/フラット両表記、大小文字無視）。
    @Test func parseKeyNames() {
        #expect(parseKey("C") == PitchClass(0))
        #expect(parseKey("c") == PitchClass(0))
        #expect(parseKey("C#") == PitchClass(1))
        #expect(parseKey("Db") == PitchClass(1))
        #expect(parseKey("D") == PitchClass(2))
        #expect(parseKey("F#") == PitchClass(6))
        #expect(parseKey("Gb") == PitchClass(6))
        #expect(parseKey("B") == PitchClass(11))
        #expect(parseKey("H") == nil)
        #expect(parseKey("") == nil)
        #expect(parseKey("C##") == nil)
    }

    /// スケール名 → Scale（ハイフン/キャメル両表記）。
    @Test func parseScaleNames() {
        #expect(parseScale("major") == .major)
        #expect(parseScale("natural-minor") == .naturalMinor)
        #expect(parseScale("naturalMinor") == .naturalMinor)
        #expect(parseScale("dorian") == .dorian)
        #expect(parseScale("major-pentatonic") == .majorPentatonic)
        #expect(parseScale("minor-pentatonic") == .minorPentatonic)
        #expect(parseScale("blues") == .blues)
        #expect(parseScale("lydian") == nil)
        #expect(parseScale("") == nil)
    }

    // MARK: - set

    /// 完全指定 set --key C --scale major。
    @Test func parseSetFull() {
        #expect(
            ok(["set", "--key", "C", "--scale", "major"]) == .set(key: PitchClass(0), scale: .major)
        )
    }

    /// オプション順序が逆でも解釈できる。
    @Test func parseSetReversedOrder() {
        let parsed = ok(["set", "--scale", "dorian", "--key", "D"])
        #expect(parsed == .set(key: PitchClass(2), scale: .dorian))
    }

    /// 部分指定 set --key D。
    @Test func parseSetKeyOnly() {
        #expect(ok(["set", "--key", "D"]) == .set(key: PitchClass(2), scale: nil))
    }

    /// 部分指定 set --scale blues。
    @Test func parseSetScaleOnly() {
        #expect(ok(["set", "--scale", "blues"]) == .set(key: nil, scale: .blues))
    }

    // MARK: - scale / root（相対）

    @Test func parseScaleUp() {
        #expect(ok(["scale", "--up"]) == .scaleStep(.up))
    }

    @Test func parseScaleDown() {
        #expect(ok(["scale", "--down"]) == .scaleStep(.down))
    }

    @Test func parseRootUp() {
        #expect(ok(["root", "--up"]) == .rootStep(.up))
    }

    @Test func parseRootDown() {
        #expect(ok(["root", "--down"]) == .rootStep(.down))
    }

    // MARK: - 異常系

    @Test func missingSubcommand() {
        #expect(err([]) == .missingSubcommand)
    }

    @Test func unknownSubcommand() {
        #expect(err(["foo"]) == .unknownSubcommand("foo"))
    }

    @Test func setUnknownOption() {
        #expect(err(["set", "--tempo", "120"]) == .unknownOption("--tempo"))
    }

    @Test func setMissingValueKey() {
        #expect(err(["set", "--key"]) == .missingValue(option: "--key"))
    }

    @Test func setMissingValueScale() {
        #expect(err(["set", "--scale"]) == .missingValue(option: "--scale"))
    }

    @Test func setInvalidKey() {
        #expect(err(["set", "--key", "H"]) == .invalidKey("H"))
    }

    @Test func setInvalidScale() {
        #expect(err(["set", "--scale", "lydian"]) == .invalidScale("lydian"))
    }

    @Test func emptySet() {
        #expect(err(["set"]) == .emptySet)
    }

    @Test func setDuplicateKey() {
        #expect(err(["set", "--key", "C", "--key", "D"]) == .conflictingArguments("--key"))
    }

    @Test func scaleMissingDirection() {
        #expect(err(["scale"]) == .missingDirection)
    }

    @Test func rootMissingDirection() {
        #expect(err(["root"]) == .missingDirection)
    }

    @Test func scaleConflictingDirection() {
        #expect(err(["scale", "--up", "--down"]) == .conflictingArguments("--up/--down"))
    }

    @Test func scaleUnknownOption() {
        #expect(err(["scale", "--sideways"]) == .unknownOption("--sideways"))
    }

    /// parse 結果を apply に通すラウンドトリップ（純粋連携の確認）。
    @Test func parseThenApply() {
        guard case .success(let cmd) = parse(["set", "--key", "F#", "--scale", "blues"]) else {
            Issue.record("parse failed")
            return
        }
        let s = apply(State(key: PitchClass(0), scale: .major), cmd)
        #expect(s == State(key: PitchClass(6), scale: .blues))
    }
}
