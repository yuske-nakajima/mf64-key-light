/// ドラッグノブの「累積ドラッグ量 → 整数値」写像を担う純粋型。
///
/// GUI のノブは上方向ドラッグで増・下方向で減らす。SwiftUI の `DragGesture` は
/// 下方向を正とする `translation.height` を返すため、GUI 側で符号を反転して
/// 「上が正の累積量 dy」を渡す前提とする（`value(forDragAmount:)` の引数は上正）。
///
/// 値域の扱いは 3 種類:
/// - 離散巡回（`wraps == true`）: 端を越えると反対端へラップ（PitchClass 0..11, Scale index 等）。
/// - 離散クランプ / 連続クランプ（`wraps == false`）: 端でクランプ（channel 1..16, velocity 0..127）。
///
/// クランプと巡回の差はラップの有無のみで、ステップ換算は共通。
public struct KnobValueMapping: Equatable, Sendable {
    /// 値の最小（含む）。
    public let lowerBound: Int
    /// 値の最大（含む）。
    public let upperBound: Int
    /// 1 ステップ進めるのに必要なドラッグ量（ポイント）。大きいほど鈍い。
    public let pointsPerStep: Double
    /// 端で反対側へラップするか。false ならクランプ。
    public let wraps: Bool

    /// - Parameters:
    ///   - lowerBound: 値の下限（含む）。
    ///   - upperBound: 値の上限（含む）。`lowerBound` 以上であること。
    ///   - pointsPerStep: 1 ステップあたりのドラッグ量（正）。
    ///   - wraps: 端でラップするか。
    public init(lowerBound: Int, upperBound: Int, pointsPerStep: Double, wraps: Bool) {
        precondition(upperBound >= lowerBound, "upperBound は lowerBound 以上であること")
        precondition(pointsPerStep > 0, "pointsPerStep は正であること")
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.pointsPerStep = pointsPerStep
        self.wraps = wraps
    }

    /// 値域に含まれる値の個数（巡回の周期）。
    public var count: Int { upperBound - lowerBound + 1 }

    /// PitchClass 0..11 を巡回するノブ（ROOT）。
    public static func pitchClass(pointsPerStep: Double = 16) -> KnobValueMapping {
        KnobValueMapping(lowerBound: 0, upperBound: 11, pointsPerStep: pointsPerStep, wraps: true)
    }

    /// Scale index 0..<count を巡回するノブ（SCALE）。
    public static func scaleIndex(count: Int, pointsPerStep: Double = 22) -> KnobValueMapping {
        precondition(count >= 1, "count は 1 以上であること")
        return KnobValueMapping(
            lowerBound: 0,
            upperBound: count - 1,
            pointsPerStep: pointsPerStep,
            wraps: true
        )
    }

    /// MIDI チャンネル 1..16 をクランプするノブ（CHANNEL）。
    public static func channel(pointsPerStep: Double = 12) -> KnobValueMapping {
        KnobValueMapping(lowerBound: 1, upperBound: 16, pointsPerStep: pointsPerStep, wraps: false)
    }

    /// velocity 0..127 をクランプするノブ（各 VEL）。
    public static func velocity(pointsPerStep: Double = 3) -> KnobValueMapping {
        KnobValueMapping(lowerBound: 0, upperBound: 127, pointsPerStep: pointsPerStep, wraps: false)
    }

    /// 累積ドラッグ量を整数ステップへ換算する（上が正 → 正ステップ）。
    ///
    /// ゼロ方向への丸めにより、`pointsPerStep` 未満の微小ドラッグはステップ 0 になる。
    public func steps(forDragAmount dy: Double) -> Int {
        Int((dy / pointsPerStep).rounded(.towardZero))
    }

    /// ドラッグ開始時の基準値と累積ドラッグ量から確定値を求める。
    ///
    /// - Parameters:
    ///   - base: ドラッグ開始時点の値（値域内）。
    ///   - dy: 上を正とする累積ドラッグ量（ポイント）。
    /// - Returns: ラップまたはクランプ後の値（必ず値域内）。
    public func value(from base: Int, dragAmount dy: Double) -> Int {
        let raw = base + steps(forDragAmount: dy)
        return normalize(raw)
    }

    /// 任意の整数を値域へ正規化する（wraps なら mod、そうでなければクランプ）。
    public func normalize(_ raw: Int) -> Int {
        if wraps {
            let n = count
            let m = (raw - lowerBound) % n
            let wrapped = m < 0 ? m + n : m
            return lowerBound + wrapped
        }
        return min(max(raw, lowerBound), upperBound)
    }
}
