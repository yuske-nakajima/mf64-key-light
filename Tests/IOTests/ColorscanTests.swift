import Testing

@testable import IO

@Suite("Colorscan")
struct ColorscanTests {
    @Test("colorscanSteps: from..to を昇順両端含みで生成する")
    func stepsAscendingInclusive() {
        let config = ColorscanConfig(note: 36, from: 0, to: 5, delayMilliseconds: 1)
        let steps = colorscanSteps(config)
        #expect(steps.map { $0.velocity } == [0, 1, 2, 3, 4, 5])
        #expect(steps.allSatisfy { $0.note == 36 })
    }

    @Test("colorscanSteps: from == to は 1 ステップ")
    func stepsSingle() {
        let steps = colorscanSteps(ColorscanConfig(note: 10, from: 7, to: 7, delayMilliseconds: 0))
        #expect(steps == [ColorscanStep(note: 10, velocity: 7)])
    }

    @Test("colorscanSteps: from > to は空")
    func stepsEmptyWhenReversed() {
        let steps = colorscanSteps(ColorscanConfig(note: 10, from: 9, to: 3, delayMilliseconds: 0))
        #expect(steps.isEmpty)
    }

    @Test("parseColorscan: 既定値（note=36, from=0, to=127, delay=300）")
    func parseDefaults() {
        guard case .success(let config) = parseColorscan([]) else {
            Issue.record("parse に失敗")
            return
        }
        #expect(config.note == Devices.colorscanDefaultNote)
        #expect(config.from == 0)
        #expect(config.to == 127)
        #expect(config.delayMilliseconds == 300)
    }

    @Test("parseColorscan: 全オプション指定")
    func parseAllOptions() {
        let result = parseColorscan(["--note", "40", "--from", "5", "--to", "20", "--delay", "50"])
        guard case .success(let config) = result else {
            Issue.record("parse に失敗")
            return
        }
        #expect(config == ColorscanConfig(note: 40, from: 5, to: 20, delayMilliseconds: 50))
    }

    @Test("parseColorscan: from が範囲外なら velocityOutOfRange")
    func parseFromOutOfRange() {
        #expect(parseColorscan(["--from", "200"]) == .failure(.velocityOutOfRange(200)))
    }

    @Test("parseColorscan: to が範囲外なら velocityOutOfRange")
    func parseToOutOfRange() {
        #expect(parseColorscan(["--to", "128"]) == .failure(.velocityOutOfRange(128)))
    }

    @Test("parseColorscan: 値欠落は missingValue")
    func parseMissingValue() {
        #expect(parseColorscan(["--from"]) == .failure(.missingValue(option: "--from")))
    }

    @Test("parseColorscan: 数値でない値は invalidValue")
    func parseInvalidValue() {
        #expect(
            parseColorscan(["--to", "abc"]) == .failure(.invalidValue(option: "--to", value: "abc"))
        )
    }

    @Test("parseColorscan: 未知オプションは unknownOption")
    func parseUnknownOption() {
        #expect(parseColorscan(["--foo"]) == .failure(.unknownOption("--foo")))
    }
}
