import Core
import IO
import SwiftUI

/// PitchClass.value → 表示用キー名（シャープ表記）。
enum KeyNames {
    static let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    static func name(_ pc: PitchClass) -> String {
        names[pc.value]
    }
}

/// MF64 8×8 グリッドを layout の結果で塗る LCD グロー調プレビュー。
///
/// root=紫 / member=水色 / outside=白。各パッドは放射グラデ + グロー shadow で点灯ライトを表す。
/// `layout(state:padMap:)` の結果駆動は維持する。
struct PadGridView: View {
    let state: Core.State

    /// 1 パッドの一辺。
    var padSize: CGFloat = 30

    private let columns = 8
    private let rows = 8

    var body: some View {
        let pads = layout(state: state, padMap: Devices.defaultPadMap)
        VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        // padMap が 64 未満でも安全に描く。範囲外は消灯(白)扱い。
                        cell(for: index < pads.count ? pads[index].color : .outside)
                    }
                }
            }
        }
    }

    private func cell(for color: LEDColor) -> some View {
        let palette = Palette.for(color)
        return RoundedRectangle(cornerRadius: DesignTokens.Radius.pad, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [palette.inner, palette.mid, palette.outer],
                    center: UnitPoint(x: 0.4, y: 0.32),
                    startRadius: 0,
                    endRadius: padSize * 0.75
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.pad, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .frame(width: padSize, height: padSize)
            .shadow(color: palette.glow, radius: palette.glowRadius)
    }

    /// パッド 1 色分の塗り 3 色 + グロー。
    private struct Palette {
        let inner: Color
        let mid: Color
        let outer: Color
        let glow: Color
        let glowRadius: CGFloat

        static func `for`(_ color: LEDColor) -> Palette {
            switch color {
            case .root:
                return Palette(
                    inner: DesignTokens.Pad.rootInner,
                    mid: DesignTokens.Pad.rootMid,
                    outer: DesignTokens.Pad.rootOuter,
                    glow: DesignTokens.Accent.glowPurple.opacity(0.8),
                    glowRadius: 7
                )
            case .member:
                return Palette(
                    inner: DesignTokens.Pad.memberInner,
                    mid: DesignTokens.Pad.memberMid,
                    outer: DesignTokens.Pad.memberOuter,
                    glow: DesignTokens.Accent.glowCyan.opacity(0.7),
                    glowRadius: 6
                )
            case .outside:
                return Palette(
                    inner: DesignTokens.Pad.outsideInner,
                    mid: DesignTokens.Pad.outsideMid,
                    outer: DesignTokens.Pad.outsideOuter,
                    glow: Color.white.opacity(0.25),
                    glowRadius: 3
                )
            }
        }
    }
}

struct PadGridView_Previews: PreviewProvider {
    static var previews: some View {
        PadGridView(state: Core.State(key: PitchClass(0), scale: .major))
            .padding(40)
            .background(
                LCDContainer { Color.clear }
                    .ignoresSafeArea()
            )
            .previewDisplayName("PadGridView")
    }
}
