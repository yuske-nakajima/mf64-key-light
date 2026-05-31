import Core
import IO
import SwiftUI

/// Scale の表示用ヘルパ（hero 名 / SCALE コントロールの略称）。
enum ScaleDisplay {
    /// hero に出す大きめのスケール名（大文字）。
    static func heroName(_ scale: Scale) -> String {
        switch scale {
        case .major: return "MAJOR"
        case .naturalMinor: return "MINOR"
        case .dorian: return "DORIAN"
        case .mixolydian: return "MIXOLYDIAN"
        case .majorPentatonic: return "MAJ PENTA"
        case .minorPentatonic: return "MIN PENTA"
        case .blues: return "BLUES"
        }
    }

    /// SCALE コントロールの 3 文字略称。
    static func abbreviation(_ scale: Scale) -> String {
        switch scale {
        case .major: return "MAJ"
        case .naturalMinor: return "MIN"
        case .dorian: return "DOR"
        case .mixolydian: return "MIX"
        case .majorPentatonic: return "MPT"
        case .minorPentatonic: return "mPT"
        case .blues: return "BLU"
        }
    }
}

/// モック上段の暗い LCD パネル（MAIN セクション）。
///
/// 横並びで ROOT ノブ / hero 表示 / 8×8 パッドプレビュー / SCALE コントロール、下にレジェンド。
/// 操作は親から渡された確定コールバック（`onRootChange` / `onScaleChange`）経由で persist される。
struct MainSection: View {
    /// 現在のキー（表示 + ノブ基準値）。
    let key: PitchClass
    /// 現在のスケール（hero 名 + SCALE 略称）。
    let scale: Scale
    /// ROOT 確定（保存 + 送信は親）。
    let onRootChange: (PitchClass) -> Void
    /// SCALE 確定（保存 + 送信は親）。
    let onScaleChange: (Scale) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            EngravedText("MAIN — KEY LIGHT", font: .oswald(13), color: DesignTokens.Engrave.normal)
            LCDContainer {
                VStack(spacing: 18) {
                    HStack(alignment: .center, spacing: 24) {
                        rootControl
                        hero
                        Spacer(minLength: 0)
                        PadGridView(state: Core.State(key: key, scale: scale))
                        scaleControl
                    }
                    legend
                }
                .padding(28)
            }
        }
    }

    // MARK: - ROOT ノブ

    private var rootControl: some View {
        VStack(spacing: 10) {
            EngravedText("ROOT", font: .oswald(12))
            DragKnob(
                // 確定は onChange のみ（MidiOutputSection と統一）。value 経由の set で
                // onRootChange が二重発火しないよう .constant にする。表示は現在キーで追従。
                value: .constant(key.value),
                mapping: .pitchClass(),
                label: "ROOT",
                onChange: { onRootChange(PitchClass($0)) }
            )
            EngravedText(
                KeyNames.name(key),
                font: .jetBrainsMono(15),
                color: DesignTokens.Engrave.strong
            )
            rootStepButtons
        }
        .frame(width: 84)
    }

    /// ノブ直下の半音ステップボタン。ドラッグとは別経路の離散 ±1 を `onRootChange`（persist）へ流す。
    private var rootStepButtons: some View {
        HStack(spacing: 8) {
            RoundSkeuoButton(
                symbol: "♭",
                caption: "DOWN",
                action: { onRootChange(PitchClass(key.value - 1)) }
            )
            RoundSkeuoButton(
                symbol: "#",
                caption: "UP",
                action: { onRootChange(PitchClass(key.value + 1)) }
            )
        }
    }

    // MARK: - hero（主役表示）

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(KeyNames.name(key))
                .font(.anton(96))
                .foregroundStyle(DesignTokens.Accent.glowPurple)
                .shadow(color: DesignTokens.Accent.glowPurple.opacity(0.85), radius: 24)
                .shadow(color: DesignTokens.Accent.primary.opacity(0.5), radius: 6)
            Text(ScaleDisplay.heroName(scale))
                .font(.oswald(26))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }

    // MARK: - SCALE コントロール

    private var scaleControl: some View {
        VStack(spacing: 8) {
            EngravedText("SCALE", font: .oswald(12))
            SkeuoButton(action: { onScaleChange(stepped(.up)) }) {
                Label("NEXT", systemImage: "chevron.up")
                    .labelStyle(.titleOnly)
            }
            EngravedText(
                ScaleDisplay.abbreviation(scale),
                font: .jetBrainsMono(15),
                color: DesignTokens.Engrave.strong
            )
            .frame(minWidth: 56)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                    .fill(DesignTokens.LCD.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            SkeuoButton(action: { onScaleChange(stepped(.down)) }) {
                Label("PREV", systemImage: "chevron.down")
                    .labelStyle(.titleOnly)
            }
        }
        .frame(width: 96)
    }

    /// 現在スケールを巡回方向に 1 つ進めた結果（Core の apply に委譲）。
    private func stepped(_ direction: Direction) -> Scale {
        apply(Core.State(key: key, scale: scale), .scaleStep(direction)).scale
    }

    // MARK: - レジェンド

    private var legend: some View {
        HStack(spacing: 20) {
            legendItem(color: DesignTokens.Pad.rootMid, label: "ROOT")
            legendItem(color: DesignTokens.Pad.memberMid, label: "SCALE")
            legendItem(color: DesignTokens.Pad.outsideMid, label: "OFF")
            Spacer()
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.8), radius: 4)
            EngravedText(label, font: .oswald(11))
        }
    }
}

struct MainSection_Previews: PreviewProvider {
    static var previews: some View {
        MainSection(
            key: PitchClass(0),
            scale: .major,
            onRootChange: { _ in },
            onScaleChange: { _ in }
        )
        .padding(32)
        .background(PlateBackground().ignoresSafeArea())
        .previewDisplayName("MainSection")
    }
}
