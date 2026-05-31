import SwiftUI

/// 微細ノイズ（グレイン）テクスチャ。決定的な擬似乱数で 1 タイルを生成し敷き詰める。
///
/// 毎フレーム再生成しないよう固定 seed で点を打ち、`drawingGroup` でラスタライズしてから
/// `.opacity` で薄く重ねる。タイルサイズは小さく保ち広い面でも軽量にする。
struct GrainOverlay: View {
    var opacity: Double = DesignTokens.Grain.opacity
    var tileSize: CGFloat = 64
    var density: Int = 220

    var body: some View {
        Canvas { context, size in
            // 固定 seed の線形合同法で決定的にノイズ点を打つ。
            var rng = SplitMix64(seed: 0x9E37_79B9_7F4A_7C15)
            let cols = Int((size.width / tileSize).rounded(.up))
            let rows = Int((size.height / tileSize).rounded(.up))
            for ty in 0...max(rows, 0) {
                for tx in 0...max(cols, 0) {
                    drawTile(
                        in: &context,
                        origin: CGPoint(x: CGFloat(tx) * tileSize, y: CGFloat(ty) * tileSize),
                        rng: &rng
                    )
                }
            }
        }
        .drawingGroup()
        .opacity(opacity)
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }

    private func drawTile(
        in context: inout GraphicsContext,
        origin: CGPoint,
        rng: inout SplitMix64
    ) {
        for _ in 0..<density {
            let x = origin.x + CGFloat(rng.nextUnit()) * tileSize
            let y = origin.y + CGFloat(rng.nextUnit()) * tileSize
            let shade = rng.nextUnit() < 0.5 ? Color.white : Color.black
            let rect = CGRect(x: x, y: y, width: 1, height: 1)
            context.fill(Path(rect), with: .color(shade))
        }
    }
}

/// 決定的な擬似乱数（SplitMix64）。グレインを再現可能にするための内部ユーティリティ。
private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// 0..<1 の Double を返す。
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}

struct GrainOverlay_Previews: PreviewProvider {
    static var previews: some View {
        PlateBackground()
            .frame(width: 360, height: 220)
            .overlay(GrainOverlay())
            .padding(40)
            .background(DesignTokens.Plate.deep)
            .previewDisplayName("GrainOverlay")
    }
}
