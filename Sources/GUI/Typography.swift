import SwiftUI

/// 同梱フォントへの `Font.custom` ヘルパ。PostScript 名は `FontRegistration` と一致させる。
///
/// 用途:
/// - `anton`: ロゴ（太く詰まったディスプレイ書体）。
/// - `permanentMarker`: 装飾スクリプト（手書き風）。
/// - `oswald`: 見出し / UI ラベル。
/// - `jetBrainsMono`: 値表示 / コマンド（等幅）。
extension Font {
    /// ロゴ用（Anton）。
    static func anton(_ size: CGFloat) -> Font {
        .custom("Anton-Regular", fixedSize: size)
    }

    /// 装飾スクリプト用（Permanent Marker）。
    static func permanentMarker(_ size: CGFloat) -> Font {
        .custom("PermanentMarker-Regular", fixedSize: size)
    }

    /// 見出し / UI ラベル用（Oswald）。
    static func oswald(_ size: CGFloat) -> Font {
        .custom("Oswald-Regular", fixedSize: size)
    }

    /// 値 / コマンド用（JetBrains Mono）。
    static func jetBrainsMono(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Regular", fixedSize: size)
    }
}
