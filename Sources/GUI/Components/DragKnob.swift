import IO
import SwiftUI

/// 上下ドラッグで回す立体ノブ。離散巡回 / 連続クランプの両方を `KnobValueMapping` で扱う。
///
/// - ドラッグ中は楽観的に `value` を更新しインジケータを回す。
/// - `onChange` は確定値ごとに呼ぶ（呼び出し側で保存 + 実機送信する）。
/// - 上方向ドラッグで増、下方向で減（`DragGesture.translation.height` を反転）。
struct DragKnob: View {
    /// 現在値（巡回/クランプ後の値域内）。
    @Binding var value: Int
    /// 値域・感度・巡回を定める写像。
    let mapping: KnobValueMapping
    /// アクセシビリティ用ラベル（例 "ROOT VEL"）。
    var label: String
    /// 値の確定コールバック（保存 + 送信は呼び出し側）。
    var onChange: (Int) -> Void

    var diameter: CGFloat = 64

    /// ドラッグ開始時の基準値。`onChanged` 中は固定し累積量で計算する。
    @State private var dragBaseValue: Int?

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [DesignTokens.Knob.bodyInner, DesignTokens.Knob.bodyOuter],
                    center: UnitPoint(x: 0.42, y: 0.36),
                    startRadius: 0,
                    endRadius: diameter * 0.72
                )
            )
            .overlay(knurlRing)
            .overlay(topHighlight)
            .overlay(indicator)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.5), lineWidth: 1))
            .frame(width: diameter, height: diameter)
            .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: 4)
            .contentShape(Circle())
            .gesture(dragGesture)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue("\(value)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    setValue(mapping.normalize(value + 1))
                case .decrement:
                    setValue(mapping.normalize(value - 1))
                @unknown default:
                    break
                }
            }
    }

    // MARK: - 描画パーツ

    /// 縁のローレット（明暗の刻み）。
    private var knurlRing: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [
                        DesignTokens.Knob.ridgeDark,
                        DesignTokens.Knob.ridgeLight,
                        DesignTokens.Knob.ridgeDark,
                        DesignTokens.Knob.ridgeLight,
                        DesignTokens.Knob.ridgeDark,
                    ],
                    center: .center
                ),
                lineWidth: diameter * 0.10
            )
    }

    /// 上方の照り（光沢ハイライト）。
    private var topHighlight: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.28), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .padding(diameter * 0.16)
    }

    /// 値に対応する指標線（-135°..+135° の 270° スイープ）。
    private var indicator: some View {
        let angle = angleForValue()
        return Capsule()
            .fill(DesignTokens.Knob.indicator)
            .frame(width: 3, height: diameter * 0.26)
            .shadow(color: DesignTokens.Accent.glowPurple.opacity(0.6), radius: 3)
            .offset(y: -diameter * 0.24)
            .rotationEffect(angle)
    }

    // MARK: - 値 ↔ 角度

    /// 値を 270° スイープ上の角度へ写す。離散/連続いずれも `count` 等分する。
    private func angleForValue() -> Angle {
        let span = 270.0
        let steps = max(mapping.count - 1, 1)
        let normalized = Double(value - mapping.lowerBound) / Double(steps)
        return .degrees(-135 + normalized * span)
    }

    // MARK: - ドラッグ

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { g in
                let base = dragBaseValue ?? value
                if dragBaseValue == nil { dragBaseValue = base }
                // translation.height は下が正。上を正の累積量に反転。
                let dy = -Double(g.translation.height)
                let next = mapping.value(from: base, dragAmount: dy)
                if next != value {
                    setValue(next)
                }
            }
            .onEnded { _ in
                dragBaseValue = nil
            }
    }

    /// 楽観更新 + 確定コールバック。
    private func setValue(_ newValue: Int) {
        value = newValue
        onChange(newValue)
    }
}

private struct DragKnobPreviewDemo: View {
    @State private var channel = 2
    @State private var velocity = 54
    @State private var root = 0

    var body: some View {
        HStack(spacing: 32) {
            knob("CHANNEL", $channel, .channel(), text: "\(channel)")
            knob("ROOT VEL", $velocity, .velocity(), text: "\(velocity)")
            knob("ROOT", $root, .pitchClass(), text: "\(root)")
        }
        .padding(48)
        .background(PlateBackground().ignoresSafeArea())
    }

    private func knob(
        _ label: String,
        _ binding: Binding<Int>,
        _ mapping: KnobValueMapping,
        text: String
    ) -> some View {
        VStack(spacing: 10) {
            EngravedText(label, font: .oswald(12))
            DragKnob(value: binding, mapping: mapping, label: label, onChange: { _ in })
            EngravedText(text, font: .jetBrainsMono(14), color: DesignTokens.Engrave.strong)
        }
    }
}

struct DragKnob_Previews: PreviewProvider {
    static var previews: some View {
        DragKnobPreviewDemo()
            .previewDisplayName("DragKnob")
    }
}
