import Core
import Foundation

/// MF64 8×8 パッドのデバイス定義。
///
/// PadMap は説明書 Appendix 1 / Fig 1（Hardware Naming Convention）のデフォルト(Bank 1)に基づく実値。
/// 色 velocity は校正前プレースホルダで、colorscan で確定する。
public enum Devices {
    /// パッド総数（8×8）。
    public static let padCount = 64

    /// 校正用に colorscan が既定で対象にする代表ノート（左下=ボタン1=note 36）。
    public static let colorscanDefaultNote = 36

    /// チャンネル既定値。tilerhyme 実機実証は ch1。説明書の factory default は ch3。
    private static let defaultMidiChannel = 1

    /// CoreMIDI 送信に使う MIDI チャンネル（1..16）。
    ///
    /// `MF64_MIDI_CHANNEL` があれば優先する。範囲外・不正値は既定にフォールバックする。
    public static var midiChannel: Int {
        guard let raw = ProcessInfo.processInfo.environment["MF64_MIDI_CHANNEL"],
            let value = Int(raw),
            (1...16).contains(value)
        else {
            return defaultMidiChannel
        }
        return value
    }

    /// パッドインデックス(0..63, 左上=0 の行優先) → MIDI ノート番号。
    ///
    /// MF64 は 4×4 の4象限で構成され、各象限内でボタン番号は左下→右→上の順。USB を上にした向きで:
    /// ```
    /// (上)  29 30 31 32 | 61 62 63 64
    ///        ...        |    ...
    /// (下)   1  2  3  4 | 33 34 35 36
    /// ```
    /// ノート番号 = ボタン番号 + 35（ボタン1=36/C1 … ボタン64=99/D#6）。
    /// GUI/レイアウトのインデックスは左上=0 の行優先のため、象限座標から都度算出する。
    public static let defaultPadMap: [Int] = buildPadMap()

    /// LEDColor → MF64 velocity 値。
    ///
    /// 校正前プレースホルダ。紫/水色/白の確定値は colorscan で採取して差し替える。
    /// 実機で各色を区別できる程度に離した仮値（root=45 / member=8 / outside=1）。
    public static func velocity(for color: LEDColor) -> UInt8 {
        switch color {
        case .root: return 45
        case .member: return 8
        case .outside: return 1
        }
    }

    /// 左上=0 の行優先インデックスごとに、象限構造からボタン番号→ノート番号を算出する。
    private static func buildPadMap() -> [Int] {
        var map = [Int](repeating: 0, count: padCount)
        for visualRow in 0..<8 {
            for col in 0..<8 {
                let isTop = visualRow < 4
                let isLeft = col < 4
                // 象限のボタン番号ベース（0始まり）: 左下=0, 左上=16, 右下=32, 右上=48。
                let base = isTop ? (isLeft ? 16 : 48) : (isLeft ? 0 : 32)
                // 象限内は下から上に増えるため、視覚行を象限内の下基準行へ反転する。
                let quadRowFromBottom = 3 - (visualRow % 4)
                let quadCol = col % 4
                let button = base + quadRowFromBottom * 4 + quadCol + 1
                map[visualRow * 8 + col] = button + 35
            }
        }
        return map
    }
}
