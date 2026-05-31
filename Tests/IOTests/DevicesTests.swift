import Testing

@testable import IO

@Suite("Devices")
struct DevicesTests {
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
}
