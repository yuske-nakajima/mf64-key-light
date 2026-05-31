import SwiftUI

/// ハードウェアプレート面（上下グラデ + リム + 内側影）を描く背景 View。
///
/// `box-shadow: inset 0 1px 0 rgba(255,255,255,.9), inset 0 -2px 4px rgba(0,0,0,.18), 0 3px 6px ...`
/// を SwiftUI のオーバーレイ stroke と影で近似する。
struct PlateBackground: View {
    var cornerRadius: CGFloat = DesignTokens.Radius.plate

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(
                LinearGradient(
                    colors: [DesignTokens.Plate.top, DesignTokens.Plate.bottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                // リム（外周の暗い縁）。
                shape.strokeBorder(DesignTokens.Plate.rim, lineWidth: 1)
            )
            .overlay(
                // 上端の明ハイライト + 下端の内側影で立体感。
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.clear,
                                Color.black.opacity(0.25),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .blur(radius: 0.5)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
    }
}

/// 任意の View をプレート面の上に載せる修飾。
struct PlateBackgroundModifier: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(PlateBackground(cornerRadius: cornerRadius))
    }
}

extension View {
    /// プレート背景を敷く。
    func plateBackground(
        cornerRadius: CGFloat = DesignTokens.Radius.plate,
        padding: CGFloat = DesignTokens.Spacing.section
    ) -> some View {
        modifier(PlateBackgroundModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

struct PlateBackground_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PlateBackground()
                .frame(width: 360, height: 160)
            Text("PLATE")
                .font(.oswald(28))
                .foregroundStyle(DesignTokens.Engrave.strong)
                .plateBackground()
        }
        .padding(40)
        .background(DesignTokens.Plate.deep)
        .previewDisplayName("PlateBackground")
    }
}
