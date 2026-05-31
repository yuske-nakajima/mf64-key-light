import SwiftUI

/// モック（シルバースキュモーフィック）のデザイントークン。色・影・角丸・間隔を一元化する。
///
/// 外側パネル/プレート/刻印は明るいシルバー系。LCD コンテナの中だけ暗い（screen-bg）。
enum DesignTokens {
    // MARK: - プレート（金属/樹脂面）

    enum Plate {
        /// 面の上端（明）。`--plate-top`。
        static let top = Color(hex: 0xF3_F3_F5)
        /// 面の下端（暗）。`--plate-bot`。
        static let bottom = Color(hex: 0xD3_D4_D9)
        /// リム（縁）。`--plate-rim`。
        static let rim = Color(hex: 0xB3_B4_BB)
        /// 最深部（彫り込みの底）。`--plate-deep`。
        static let deep = Color(hex: 0x9A_9B_A3)
    }

    // MARK: - LCD（暗パネル）

    enum LCD {
        /// パネル背景。`--screen-bg`。
        static let background = Color(hex: 0x0A_0C_12)
        /// 上端の弱い明（`radial 130% 120% at 50% 0%` の内側色）。
        static let glowTop = Color(hex: 0x15_17_1F)
        /// パネル外周の最深。
        static let edge = Color(hex: 0x07_08_0C)
    }

    // MARK: - アクセント / グロー

    enum Accent {
        /// 主アクセント（紫）。`--accent`。
        static let primary = Color(hex: 0x8B_5C_F6)
        /// LCD のルートグロー（紫, hero/pad）。
        static let glowPurple = Color(hex: 0xA8_55_F7)
        /// LCD のメンバーグロー（水色, pad）。
        static let glowCyan = Color(hex: 0x38_BD_F8)
        /// 接続 ON のステータス（緑）。
        static let online = Color(hex: 0x34_D3_99)
    }

    // MARK: - パッド（3 色）

    enum Pad {
        /// ルート（紫）の放射グラデ 3 色: 内 / 中 / 外。
        static let rootInner = Color(hex: 0xD8_B4_FE)
        static let rootMid = Color(hex: 0xA8_55_F7)
        static let rootOuter = Color(hex: 0x7E_22_CE)
        /// メンバー（水色）。
        static let memberInner = Color(hex: 0xBA_E6_FD)
        static let memberMid = Color(hex: 0x38_BD_F8)
        static let memberOuter = Color(hex: 0x0E_A5_E9)
        /// アウトサイド（白）。
        static let outsideInner = Color(hex: 0xFB_FB_FD)
        static let outsideMid = Color(hex: 0xE6_E7_EC)
        static let outsideOuter = Color(hex: 0xC9_CA_D2)
    }

    // MARK: - ノブ

    enum Knob {
        /// 本体放射グラデ（`circle at 42% 36%`）の内 / 外。
        static let bodyInner = Color(hex: 0x4A_4B_53)
        static let bodyOuter = Color(hex: 0x1C_1D_22)
        /// 縁ローレットの明暗（conic ridge）。
        static let ridgeLight = Color(hex: 0x3D_3E_46)
        static let ridgeDark = Color(hex: 0x23_24_29)
        /// インジケータ（指標線）。
        static let indicator = Color(hex: 0xC2_C5_CF)
    }

    // MARK: - ボタン

    enum Button {
        /// 立体ボタン面の上 / 下（明るいシルバー）。
        static let top = Color(hex: 0xEC_ED_F0)
        static let bottom = Color(hex: 0xC9_CA_D1)
        /// ボタン上の刻印テキスト色（明るい面で読める濃いグレー）。
        static let label = Color(hex: 0x4A_4C_55)
    }

    // MARK: - 刻印テキスト

    enum Engrave {
        /// 通常刻印色。`--eng`。
        static let normal = Color(hex: 0x9D_A0_AB)
        /// 強い刻印色。`--eng-strong`。
        static let strong = Color(hex: 0xC2_C5_CF)
        /// 彫り込みの暗側影（上）。`--eng-shadow` 0 1px 0 rgba(0,0,0,.6)。
        static let shadowDark = Color.black.opacity(0.6)
        /// 明るい面の刻印の下に当てる白ハイライト。
        static let highlight = Color.white.opacity(0.85)
    }

    // MARK: - グレイン

    enum Grain {
        /// 重ねる不透明度。`--grain`。
        static let opacity: Double = 0.06
    }

    // MARK: - 角丸

    enum Radius {
        static let plate: CGFloat = 18
        static let lcd: CGFloat = 16
        static let button: CGFloat = 8
        static let pad: CGFloat = 6
        static let chip: CGFloat = 5
    }

    // MARK: - 間隔

    enum Spacing {
        static let section: CGFloat = 24
        static let element: CGFloat = 12
        static let tight: CGFloat = 6
    }
}

extension Color {
    /// 0xRRGGBB の整数から不透明色を作る。
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
