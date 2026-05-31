import Core

/// MIDI チャンネルと 3 色 velocity を保持する設定。
///
/// 既定値は実機の入力モニタ・colorscan で採取した参考値（CLI help と GUI に表示する）。
/// MF64 の LED 色は Note On(`0x90 + (channel-1)`, note, velocity) で設定する（velocity が色コード）。
public struct Settings: Equatable, Sendable {
    /// MIDI チャンネル（1..16）。
    public var midiChannel: Int
    /// ルート音の velocity（紫）。
    public var colorRoot: UInt8
    /// スケール構成音の velocity（水色）。
    public var colorMember: UInt8
    /// スケール外の velocity（白）。
    public var colorOutside: UInt8

    public init(midiChannel: Int, colorRoot: UInt8, colorMember: UInt8, colorOutside: UInt8) {
        self.midiChannel = midiChannel
        self.colorRoot = colorRoot
        self.colorMember = colorMember
        self.colorOutside = colorOutside
    }

    /// 参考値（実機モニタで Bank 2 = ch2 を確認、色は colorscan で採取）。
    public static let `default` = Settings(
        midiChannel: 2,
        colorRoot: 54,  // 紫
        colorMember: 36,  // 水色
        colorOutside: 3  // 白
    )

    /// LEDColor → velocity（色コード）を引く。
    public func velocity(for color: LEDColor) -> UInt8 {
        switch color {
        case .root: return colorRoot
        case .member: return colorMember
        case .outside: return colorOutside
        }
    }

    /// midiChannel が 1..16 かを返す。色は UInt8 のため 0..127 に常に収まる。
    public var isValid: Bool {
        (1...16).contains(midiChannel)
    }
}
