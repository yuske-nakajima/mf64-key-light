import Core
import IO
import SwiftUI

/// モック中段の「01 MIDI OUTPUT」セクション。
///
/// CHANNEL / ROOT VEL / MEMBER VEL / OUT VEL のノブ群、FACTORY REF 参考値表。
/// ノブ確定は親へ `onSettingsChange` で渡し、親が saveSettings + pushToDevice する。
struct MidiOutputSection: View {
    /// 現在の設定（ノブ get + FACTORY REF 表示の基準）。
    let settings: IO.Settings
    /// 設定確定（保存 + 送信は親）。
    let onSettingsChange: (IO.Settings) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            EngravedText("01 — MIDI OUTPUT", font: .oswald(13), color: DesignTokens.Engrave.normal)
            LCDContainer {
                HStack(alignment: .top, spacing: 28) {
                    knobRow
                    Spacer(minLength: 12)
                    factoryRef
                }
                .padding(28)
            }
        }
    }

    // MARK: - ノブ群

    private var knobRow: some View {
        HStack(alignment: .top, spacing: 22) {
            knob(
                label: "CHANNEL",
                value: settings.midiChannel,
                mapping: .channel(),
                display: "\(settings.midiChannel)",
                onChange: { newValue in
                    var updated = settings
                    updated.midiChannel = newValue
                    onSettingsChange(updated)
                }
            )
            velocityKnob(label: "ROOT VEL", keyPath: \.colorRoot)
            velocityKnob(label: "MEMBER VEL", keyPath: \.colorMember)
            velocityKnob(label: "OUT VEL", keyPath: \.colorOutside)
        }
    }

    /// velocity（0..127）ノブ 1 本。keyPath で対象色を切り替える。
    private func velocityKnob(
        label: String,
        keyPath: WritableKeyPath<IO.Settings, UInt8>
    ) -> some View {
        let current = Int(settings[keyPath: keyPath])
        return knob(
            label: label,
            value: current,
            mapping: .velocity(),
            display: "\(current)",
            onChange: { newValue in
                var updated = settings
                updated[keyPath: keyPath] = UInt8(clamping: newValue)
                onSettingsChange(updated)
            }
        )
    }

    /// ラベル + DragKnob + 値表示（JetBrains Mono）の 1 本分。
    private func knob(
        label: String,
        value: Int,
        mapping: KnobValueMapping,
        display: String,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(spacing: 10) {
            EngravedText(label, font: .oswald(11))
            DragKnob(
                value: .constant(value),
                mapping: mapping,
                label: label,
                onChange: onChange
            )
            EngravedText(display, font: .jetBrainsMono(15), color: DesignTokens.Engrave.strong)
                .frame(minWidth: 44)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                        .fill(DesignTokens.LCD.background)
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: DesignTokens.Radius.chip,
                                style: .continuous
                            )
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
        }
        .frame(width: 84)
    }

    // MARK: - FACTORY REF

    private var factoryRef: some View {
        VStack(alignment: .leading, spacing: 8) {
            EngravedText("FACTORY REF", font: .oswald(11), color: DesignTokens.Engrave.strong)
            refRow("ch", "\(IO.Settings.default.midiChannel)")
            refRow("purple", "\(IO.Settings.default.colorRoot)")
            refRow("cyan", "\(IO.Settings.default.colorMember)")
            refRow("white", "\(IO.Settings.default.colorOutside)")
        }
        .padding(14)
        .frame(width: 200, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                .fill(DesignTokens.LCD.background)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func refRow(_ label: String, _ value: String) -> some View {
        HStack {
            EngravedText(label, font: .oswald(12))
            Spacer()
            EngravedText(value, font: .jetBrainsMono(13), color: DesignTokens.Engrave.strong)
        }
    }
}

struct MidiOutputSection_Previews: PreviewProvider {
    static var previews: some View {
        MidiOutputSection(
            settings: .default,
            onSettingsChange: { _ in }
        )
        .padding(32)
        .background(PlateBackground().ignoresSafeArea())
        .previewDisplayName("MidiOutputSection")
    }
}
