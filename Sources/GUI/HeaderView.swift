import IO
import SwiftUI

/// アプリ最上段のヘッダー。左に「MF64 key light」ロゴ、右に CoreMIDI 接続ステータス。
///
/// 接続状態は `MIDIConnectionMonitor` が 0.5 秒ポーリングで保持する `@State` を受け取り、
/// 接続=点灯 / 非接続=減光で表示する。
struct HeaderView: View {
    /// MF64 が接続されているか（ポーリングで更新される）。
    let isConnected: Bool

    var body: some View {
        HStack(alignment: .center) {
            logo
            Spacer()
            connectionStatus
        }
    }

    /// 「MF64」（Anton 大）+「key light」（Permanent Marker スクリプト, 紫アクセント下線）。
    private var logo: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("MF64")
                .font(.anton(40))
                .foregroundStyle(DesignTokens.Engrave.strong)
                .engraved()
            Text("key light")
                .font(.permanentMarker(26))
                .foregroundStyle(DesignTokens.Accent.primary)
                .overlay(alignment: .bottom) {
                    // スクリプト下のアクセント下線。
                    DesignTokens.Accent.primary
                        .frame(height: 3)
                        .offset(y: 4)
                        .shadow(color: DesignTokens.Accent.glowPurple.opacity(0.7), radius: 4)
                }
        }
    }

    /// 右上の「CORE MIDI」接続ステータス。点 + ラベル。
    private var connectionStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? DesignTokens.Accent.online : DesignTokens.Engrave.normal)
                .frame(width: 8, height: 8)
                .shadow(
                    color: isConnected ? DesignTokens.Accent.online : .clear,
                    radius: isConnected ? 5 : 0
                )
            EngravedText(
                "CORE MIDI",
                font: .oswald(12),
                color: isConnected ? DesignTokens.Engrave.strong : DesignTokens.Engrave.normal
            )
        }
        .opacity(isConnected ? 1 : 0.55)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HeaderView(isConnected: true)
            HeaderView(isConnected: false)
        }
        .padding(32)
        .background(PlateBackground().ignoresSafeArea())
        .previewDisplayName("HeaderView")
    }
}
