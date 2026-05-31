import Core
import Testing

@testable import IO

@Suite("KnobValueMapping")
struct KnobValueMappingTests {
    @Test("steps はゼロ方向丸め: 上正・下負・しきい未満は 0")
    func stepsTowardZero() {
        let m = KnobValueMapping(lowerBound: 0, upperBound: 100, pointsPerStep: 10, wraps: false)
        #expect(m.steps(forDragAmount: 0) == 0)
        #expect(m.steps(forDragAmount: 9) == 0)
        #expect(m.steps(forDragAmount: -9) == 0)
        #expect(m.steps(forDragAmount: 10) == 1)
        #expect(m.steps(forDragAmount: 25) == 2)
        #expect(m.steps(forDragAmount: -10) == -1)
        #expect(m.steps(forDragAmount: -25) == -2)
    }

    @Test("pitchClass 巡回: 上端 11 から +1 で 0、下端 0 から -1 で 11")
    func pitchClassWrap() {
        let m = KnobValueMapping.pitchClass(pointsPerStep: 10)
        #expect(m.value(from: 11, dragAmount: 10) == 0)
        #expect(m.value(from: 0, dragAmount: -10) == 11)
        #expect(m.value(from: 0, dragAmount: 10) == 1)
        #expect(m.value(from: 5, dragAmount: 0) == 5)
    }

    @Test("pitchClass 巡回: 1 周超の大ドラッグも値域内へ写る")
    func pitchClassMultiWrap() {
        let m = KnobValueMapping.pitchClass(pointsPerStep: 10)
        // 13 ステップ上 → 0 起点で (0+13) mod 12 = 1
        #expect(m.value(from: 0, dragAmount: 130) == 1)
        // 13 ステップ下 → 0 起点で (0-13) mod 12 = 11
        #expect(m.value(from: 0, dragAmount: -130) == 11)
        // ちょうど 12 ステップは同値へ戻る
        #expect(m.value(from: 3, dragAmount: 120) == 3)
    }

    @Test("channel クランプ: 1..16 の両端でクランプしラップしない")
    func channelClamp() {
        let m = KnobValueMapping.channel(pointsPerStep: 10)
        #expect(m.value(from: 16, dragAmount: 100) == 16)
        #expect(m.value(from: 1, dragAmount: -100) == 1)
        #expect(m.value(from: 1, dragAmount: 50) == 6)
        #expect(m.value(from: 16, dragAmount: -50) == 11)
    }

    @Test("velocity クランプ: 0 と 127 の境界で止まる")
    func velocityClamp() {
        let m = KnobValueMapping.velocity(pointsPerStep: 3)
        #expect(m.value(from: 0, dragAmount: -300) == 0)
        #expect(m.value(from: 127, dragAmount: 300) == 127)
        #expect(m.value(from: 0, dragAmount: 9) == 3)
        #expect(m.value(from: 127, dragAmount: -9) == 124)
        #expect(m.value(from: 64, dragAmount: 0) == 64)
    }

    @Test("scaleIndex 巡回: count に応じて端でラップ")
    func scaleIndexWrap() {
        let m = KnobValueMapping.scaleIndex(count: 7, pointsPerStep: 10)
        #expect(m.count == 7)
        #expect(m.value(from: 6, dragAmount: 10) == 0)
        #expect(m.value(from: 0, dragAmount: -10) == 6)
    }

    @Test("normalize: 巡回は負値も値域へ、クランプは範囲外を端へ")
    func normalizeBoundaries() {
        let wrap = KnobValueMapping(lowerBound: 0, upperBound: 11, pointsPerStep: 1, wraps: true)
        #expect(wrap.normalize(-1) == 11)
        #expect(wrap.normalize(12) == 0)
        #expect(wrap.normalize(25) == 1)

        let clamp = KnobValueMapping(lowerBound: 1, upperBound: 16, pointsPerStep: 1, wraps: false)
        #expect(clamp.normalize(-5) == 1)
        #expect(clamp.normalize(0) == 1)
        #expect(clamp.normalize(99) == 16)
        #expect(clamp.normalize(8) == 8)
    }

    @Test("非ゼロ下限の巡回: lowerBound を考慮した mod になる")
    func wrapWithNonZeroLowerBound() {
        // 1..4 を巡回（count=4）。4 から +1 で 1 に戻る。
        let m = KnobValueMapping(lowerBound: 1, upperBound: 4, pointsPerStep: 1, wraps: true)
        #expect(m.value(from: 4, dragAmount: 1) == 1)
        #expect(m.value(from: 1, dragAmount: -1) == 4)
        #expect(m.normalize(5) == 1)
        #expect(m.normalize(0) == 4)
    }
}
