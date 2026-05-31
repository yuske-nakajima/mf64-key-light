import Core

/// MF64 8×8 パッドのデバイス定義。
///
/// 重要: ここの値はすべて**ダミー**。実機の MIDI ノート割り当てと LED velocity は
/// 実機採取で確定する（PR2）。それまでは型と結線を成立させるための仮値を置く。
public enum Devices {
    /// パッド総数（8×8）。
    public static let padCount = 64

    /// パッドインデックス(0..63) → MIDI ノート番号。
    ///
    /// ダミー値: インデックスをそのままノート番号にする（0..63）。
    /// オクターブ循環や実機レイアウトは PR2 で差し替える。
    public static let dummyPadMap: [Int] = Array(0..<padCount)

    /// LEDColor → MF64 velocity 値。
    ///
    /// ダミー値: root=1 / member=2 / outside=3。実機の色対応は PR2 で確定する。
    public static func velocity(for color: LEDColor) -> UInt8 {
        switch color {
        case .root: return 1
        case .member: return 2
        case .outside: return 3
        }
    }
}
