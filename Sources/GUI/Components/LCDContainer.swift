import SwiftUI

/// 暗い LCD 画面コンテナ。深い放射背景 + 内側の暗い縁影 + ベゼルで「沈んだガラス面」を作る。
///
/// `radial-gradient(130% 120% at 50% 0%, #15171f, #07080c 75%)` と
/// `box-shadow: inset 0 0 70px 10px rgba(0,0,0,.7)` を近似する。子に紫/水色グローを載せられる。
struct LCDContainer<Content: View>: View {
    var cornerRadius: CGFloat = DesignTokens.Radius.lcd
    @ViewBuilder var content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content()
            .background(
                shape.fill(
                    RadialGradient(
                        colors: [DesignTokens.LCD.glowTop, DesignTokens.LCD.edge],
                        center: .top,
                        startRadius: 0,
                        endRadius: 600
                    )
                )
            )
            .background(shape.fill(DesignTokens.LCD.background))
            .overlay(
                // 内側の暗い縁影（画面の沈み込み）。
                shape
                    .stroke(Color.black.opacity(0.7), lineWidth: 14)
                    .blur(radius: 10)
                    .mask(shape)
            )
            .overlay(
                // 細いベゼル明線。
                shape.strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
            .clipShape(shape)
            .overlay(
                // 外周ベゼルの暗い縁。
                shape.strokeBorder(DesignTokens.Plate.rim, lineWidth: 1.5)
            )
    }
}

struct LCDContainer_Previews: PreviewProvider {
    static var previews: some View {
        LCDContainer {
            HStack {
                Text("C")
                    .font(.anton(72))
                    .foregroundStyle(DesignTokens.Accent.glowPurple)
                    .shadow(color: DesignTokens.Accent.glowPurple, radius: 18)
                Spacer()
                Text("MAJOR")
                    .font(.oswald(28))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(40)
            .frame(width: 460, height: 240)
        }
        .padding(40)
        .background(PlateBackground().ignoresSafeArea())
        .previewDisplayName("LCDContainer")
    }
}
