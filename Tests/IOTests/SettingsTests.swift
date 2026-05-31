import Core
import Testing

@testable import IO

@Suite("Settings")
struct SettingsTests {
    @Test("default は参考値 ch2 / 紫54 / 水色36 / 白3")
    func defaultIsReferenceValues() {
        let s = Settings.default
        #expect(s.midiChannel == 2)
        #expect(s.colorRoot == 54)
        #expect(s.colorMember == 36)
        #expect(s.colorOutside == 3)
    }

    @Test("velocity(for:) は root/member/outside を各色 velocity へ写す")
    func velocityMapping() {
        let s = Settings(midiChannel: 1, colorRoot: 10, colorMember: 20, colorOutside: 30)
        #expect(s.velocity(for: .root) == 10)
        #expect(s.velocity(for: .member) == 20)
        #expect(s.velocity(for: .outside) == 30)
    }

    @Test("isValid: channel 1..16 が有効、範囲外は無効")
    func channelValidation() {
        for ch in [1, 2, 8, 16] {
            #expect(
                Settings(midiChannel: ch, colorRoot: 0, colorMember: 0, colorOutside: 0).isValid
            )
        }
        for ch in [0, 17, -1, 100] {
            #expect(
                !Settings(midiChannel: ch, colorRoot: 0, colorMember: 0, colorOutside: 0).isValid
            )
        }
    }

    @Test("色は UInt8 のため境界値 0 と 127 を保持する")
    func colorBoundaries() {
        let s = Settings(midiChannel: 1, colorRoot: 0, colorMember: 127, colorOutside: 64)
        #expect(s.colorRoot == 0)
        #expect(s.colorMember == 127)
        #expect(s.colorOutside == 64)
    }
}
