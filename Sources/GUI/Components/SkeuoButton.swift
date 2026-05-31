import SwiftUI

/// 立体ボタン（NEXT/PREV/MAJ/COPY/COLOR SCAN/GO TO 共通）。押下で凹む。
///
/// 通常時は上明・下暗のグラデ + 上端ハイライト + 落ち影。押下時はグラデ反転 + 内側影で凹みを表す。
struct SkeuoButton<Label: View>: View {
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            label()
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minWidth: 44)
        }
        .buttonStyle(SkeuoButtonStyle())
    }
}

/// `SkeuoButton` の見た目を提供する `ButtonStyle`。押下状態は `configuration.isPressed` で受ける。
struct SkeuoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
        let pressed = configuration.isPressed
        configuration.label
            .font(.oswald(13))
            .foregroundStyle(DesignTokens.Engrave.strong)
            .background(
                shape.fill(
                    LinearGradient(
                        colors: pressed
                            ? [DesignTokens.Button.bottom, DesignTokens.Button.top]
                            : [DesignTokens.Button.top, DesignTokens.Button.bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .overlay(
                shape.strokeBorder(
                    pressed ? Color.black.opacity(0.4) : Color.white.opacity(0.10),
                    lineWidth: 1
                )
            )
            .overlay(
                // 押下時は内側影で凹みを、通常時は上端ハイライト。
                shape
                    .stroke(
                        pressed ? Color.black.opacity(0.6) : Color.white.opacity(0.10),
                        lineWidth: 2
                    )
                    .blur(radius: 2)
                    .offset(y: pressed ? 1 : -1)
                    .mask(shape)
            )
            .shadow(
                color: Color.black.opacity(pressed ? 0.1 : 0.4),
                radius: pressed ? 1 : 3,
                x: 0,
                y: pressed ? 1 : 2
            )
            .offset(y: pressed ? 1 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

struct SkeuoButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            SkeuoButton(action: {}) { Text("NEXT") }
            SkeuoButton(action: {}) { Text("COPY") }
            SkeuoButton(action: {}) {
                Label("COLOR SCAN", systemImage: "sparkles")
            }
        }
        .padding(40)
        .background(PlateBackground().ignoresSafeArea())
        .previewDisplayName("SkeuoButton")
    }
}
