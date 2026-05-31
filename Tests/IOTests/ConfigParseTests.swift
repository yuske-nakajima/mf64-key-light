import Testing

@testable import IO

@Suite("ConfigParse")
struct ConfigParseTests {
    private let base = Settings(midiChannel: 2, colorRoot: 54, colorMember: 36, colorOutside: 3)

    @Test("引数なしは base をそのまま返す")
    func emptyReturnsBase() {
        #expect(parseConfig([], base: base) == .success(base))
    }

    @Test("指定した項目だけを上書きし、残りは base を維持する")
    func partialUpdate() {
        let result = parseConfig(["--channel", "3", "--root", "50"], base: base)
        #expect(
            result
                == .success(
                    Settings(midiChannel: 3, colorRoot: 50, colorMember: 36, colorOutside: 3)
                )
        )
    }

    @Test("全項目を更新できる")
    func fullUpdate() {
        let result = parseConfig(
            ["--channel", "16", "--root", "1", "--member", "2", "--outside", "3"],
            base: base
        )
        let expected = Settings(midiChannel: 16, colorRoot: 1, colorMember: 2, colorOutside: 3)
        #expect(result == .success(expected))
    }

    @Test("channel 範囲外はエラー")
    func channelOutOfRange() {
        #expect(parseConfig(["--channel", "0"], base: base) == .failure(.channelOutOfRange(0)))
        #expect(parseConfig(["--channel", "17"], base: base) == .failure(.channelOutOfRange(17)))
    }

    @Test("color 範囲外はエラー")
    func colorOutOfRange() {
        #expect(
            parseConfig(["--root", "128"], base: base)
                == .failure(.colorOutOfRange(option: "--root", value: 128))
        )
        #expect(
            parseConfig(["--outside", "-1"], base: base)
                == .failure(.colorOutOfRange(option: "--outside", value: -1))
        )
    }

    @Test("値が数値でない場合はエラー")
    func invalidValue() {
        #expect(
            parseConfig(["--channel", "abc"], base: base)
                == .failure(.invalidValue(option: "--channel", value: "abc"))
        )
    }

    @Test("値が欠落している場合はエラー")
    func missingValue() {
        #expect(
            parseConfig(["--root"], base: base) == .failure(.missingValue(option: "--root"))
        )
    }

    @Test("未知のオプションはエラー")
    func unknownOption() {
        #expect(
            parseConfig(["--foo", "1"], base: base) == .failure(.unknownOption("--foo"))
        )
    }

    @Test("channel 境界値 1 と 16 は受理する")
    func channelBoundaries() {
        #expect(
            parseConfig(["--channel", "1"], base: base).map { $0.midiChannel } == .success(1)
        )
        #expect(
            parseConfig(["--channel", "16"], base: base).map { $0.midiChannel } == .success(16)
        )
    }

    @Test("color 境界値 0 と 127 は受理する")
    func colorBoundaries() {
        #expect(
            parseConfig(["--root", "0", "--member", "127"], base: base).map {
                ($0.colorRoot, $0.colorMember)
            }.map { $0.0 } == .success(0)
        )
    }
}
