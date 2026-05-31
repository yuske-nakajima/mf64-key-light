import Testing

@testable import Core

@Suite("State")
struct StateTests {
    private func state(_ key: Int, _ scale: Scale) -> State {
        State(key: PitchClass(key), scale: scale)
    }

    /// set: key だけ指定すると scale は維持される。
    @Test func applySetKeyOnly() {
        let r = apply(state(0, .major), .set(key: PitchClass(2), scale: nil))
        #expect(r.key == PitchClass(2))
        #expect(r.scale == .major)
    }

    /// set: scale だけ指定すると key は維持される。
    @Test func applySetScaleOnly() {
        let r = apply(state(0, .major), .set(key: nil, scale: .dorian))
        #expect(r.key == PitchClass(0))
        #expect(r.scale == .dorian)
    }

    /// set: 両方指定すると両方差し替わる。
    @Test func applySetBoth() {
        let r = apply(state(0, .major), .set(key: PitchClass(7), scale: .blues))
        #expect(r == state(7, .blues))
    }

    /// scaleStep up は cycle の次へ進む。
    @Test func scaleStepUp() {
        #expect(apply(state(0, .major), .scaleStep(.up)).scale == .naturalMinor)
        #expect(apply(state(0, .naturalMinor), .scaleStep(.up)).scale == .dorian)
        #expect(apply(state(0, .minorPentatonic), .scaleStep(.up)).scale == .blues)
    }

    /// scaleStep down は cycle の前へ戻る。
    @Test func scaleStepDown() {
        #expect(apply(state(0, .naturalMinor), .scaleStep(.down)).scale == .major)
        #expect(apply(state(0, .blues), .scaleStep(.down)).scale == .minorPentatonic)
    }

    /// scaleStep のラップ: 末尾 blues から up で先頭 major へ。
    @Test func scaleStepWrapUp() {
        #expect(apply(state(0, .blues), .scaleStep(.up)).scale == .major)
    }

    /// scaleStep のラップ: 先頭 major から down で末尾 blues へ。
    @Test func scaleStepWrapDown() {
        #expect(apply(state(0, .major), .scaleStep(.down)).scale == .blues)
    }

    /// scaleStep は key を変えない。
    @Test func scaleStepKeepsKey() {
        #expect(apply(state(5, .major), .scaleStep(.up)).key == PitchClass(5))
    }

    /// rootStep up は +1。
    @Test func rootStepUp() {
        #expect(apply(state(0, .major), .rootStep(.up)).key == PitchClass(1))
        #expect(apply(state(5, .major), .rootStep(.up)).key == PitchClass(6))
    }

    /// rootStep down は -1。
    @Test func rootStepDown() {
        #expect(apply(state(2, .major), .rootStep(.down)).key == PitchClass(1))
    }

    /// rootStep のラップ: B(11) から up で C(0)。
    @Test func rootStepWrapUp() {
        #expect(apply(state(11, .major), .rootStep(.up)).key == PitchClass(0))
    }

    /// rootStep のラップ: C(0) から down で B(11)。
    @Test func rootStepWrapDown() {
        #expect(apply(state(0, .major), .rootStep(.down)).key == PitchClass(11))
    }

    /// rootStep は scale を変えない。
    @Test func rootStepKeepsScale() {
        #expect(apply(state(0, .dorian), .rootStep(.up)).scale == .dorian)
    }

    /// 冪等性確認: 同じ入力で同じ結果を返す。
    @Test func applyDeterministic() {
        let s = state(3, .mixolydian)
        let cmd = Command.scaleStep(.up)
        #expect(apply(s, cmd) == apply(s, cmd))
    }
}
