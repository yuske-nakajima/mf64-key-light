import Foundation
import Testing

@testable import IO

@Suite("Devices")
struct DevicesTests {
    /// MF64_MIDI_CHANNEL を読むテストはプロセス共有 env を触るため直列化する。
    @Suite(.serialized)
    struct MidiChannelEnv {
        @Test("環境変数未設定なら既定 1")
        func defaultChannel() {
            unsetenv("MF64_MIDI_CHANNEL")
            #expect(Devices.midiChannel == 1)
        }

        @Test("範囲内の環境変数を優先する")
        func envOverride() {
            setenv("MF64_MIDI_CHANNEL", "3", 1)
            defer { unsetenv("MF64_MIDI_CHANNEL") }
            #expect(Devices.midiChannel == 3)
        }

        @Test("範囲外/不正は既定 1 にフォールバック")
        func envFallback() {
            defer { unsetenv("MF64_MIDI_CHANNEL") }
            for invalid in ["0", "17", "-1", "abc", ""] {
                setenv("MF64_MIDI_CHANNEL", invalid, 1)
                #expect(Devices.midiChannel == 1)
            }
        }
    }

    /// 左上=0 の行優先で、説明書 Fig 1 の物理配置に対応するノート番号を持つ。
    @Test func padMapCorners() {
        let map = Devices.defaultPadMap
        #expect(map.count == 64)
        #expect(map[0] == 64)  // 左上 = ボタン29 = note 64
        #expect(map[7] == 99)  // 右上 = ボタン64 = note 99
        #expect(map[56] == 36)  // 左下 = ボタン1 = note 36
        #expect(map[63] == 71)  // 右下 = ボタン36 = note 71
    }

    /// 象限境界の代表点（上から2行目の左端・右半分の最下行など）。
    @Test func padMapQuadrantBoundaries() {
        let map = Devices.defaultPadMap
        #expect(map[8] == 60)  // 2行目左端 = ボタン25 = note 60
        #expect(map[4] == 96)  // 最上行・右半分左端 = ボタン61 = note 96
        #expect(map[60] == 68)  // 最下行・右半分左端 = ボタン33 = note 68
    }

    /// 全64パッドが note 36..99 を重複なく1つずつ持つ（半音階の全単射）。
    @Test func padMapIsBijectionOf36to99() {
        #expect(Set(Devices.defaultPadMap) == Set(36...99))
    }

    /// 色 velocity は3色とも異なる（実機で区別可能）。
    @Test("velocity: root/member/outside が相異なる")
    func velocityDistinct() {
        let root = Devices.velocity(for: .root)
        let member = Devices.velocity(for: .member)
        let outside = Devices.velocity(for: .outside)
        #expect(Set([root, member, outside]).count == 3)
    }
}
