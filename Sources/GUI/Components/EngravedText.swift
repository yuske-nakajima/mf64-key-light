import SwiftUI

/// 刻印（彫り込み）風テキスト。下に明ハイライト・上に暗影を重ね、面に彫られた印象を作る。
///
/// `text-shadow: 0 1px 0 rgba(255,255,255,.6), 0 1px 0 rgba(0,0,0,.5)` の上下二重影を近似する。
struct EngravedText: View {
    let text: String
    var font: Font
    var color: Color = DesignTokens.Engrave.normal

    init(_ text: String, font: Font, color: Color = DesignTokens.Engrave.normal) {
        self.text = text
        self.font = font
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            // 下方向の明ハイライト（彫りの底に当たる反射）。
            .shadow(color: DesignTokens.Engrave.highlight, radius: 0, x: 0, y: 1)
            // 上方向の暗影（彫りの縁の落ち込み）。
            .shadow(color: DesignTokens.Engrave.shadowDark, radius: 0.5, x: 0, y: -0.5)
    }
}

/// テキスト以外の View にも刻印影を付ける修飾。
struct EngraveEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: DesignTokens.Engrave.highlight, radius: 0, x: 0, y: 1)
            .shadow(color: DesignTokens.Engrave.shadowDark, radius: 0.5, x: 0, y: -0.5)
    }
}

extension View {
    /// 刻印影（上下二重）を付ける。
    func engraved() -> some View {
        modifier(EngraveEffect())
    }
}

struct EngravedText_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 16) {
            EngravedText("ROOT", font: .oswald(20))
            EngravedText("MIDI OUTPUT", font: .oswald(24), color: DesignTokens.Engrave.strong)
            EngravedText("mf64 set --key C --scale major", font: .jetBrainsMono(14))
        }
        .padding(40)
        .background(PlateBackground().ignoresSafeArea())
        .previewDisplayName("EngravedText")
    }
}
