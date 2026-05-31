/// 0..11 の音名クラス（mod12）。整数ラッパで、生成時に常に正規化される。
public struct PitchClass: Hashable, Sendable {
    public let value: Int

    /// 任意の整数を mod12 に正規化して保持する（負値も 0..11 に丸める）。
    public init(_ raw: Int) {
        let m = raw % 12
        self.value = m < 0 ? m + 12 : m
    }
}

/// スケール種別。巡回順（up は次, down は前, 端でラップ）は `cycle` の並びで定義する。
public enum Scale: String, CaseIterable, Sendable {
    case major
    case naturalMinor
    case dorian
    case mixolydian
    case majorPentatonic
    case minorPentatonic
    case blues

    /// scaleStep の巡回順。この配列順で up/down/ラップを決める。
    public static let cycle: [Scale] = [
        .major,
        .naturalMinor,
        .dorian,
        .mixolydian,
        .majorPentatonic,
        .minorPentatonic,
        .blues,
    ]

    /// ルートからの半音オフセット集合（宣言的定義）。
    public var offsets: [Int] {
        switch self {
        case .major: return [0, 2, 4, 5, 7, 9, 11]
        case .naturalMinor: return [0, 2, 3, 5, 7, 8, 10]
        case .dorian: return [0, 2, 3, 5, 7, 9, 10]
        case .mixolydian: return [0, 2, 4, 5, 7, 9, 10]
        case .majorPentatonic: return [0, 2, 4, 7, 9]
        case .minorPentatonic: return [0, 3, 5, 7, 10]
        case .blues: return [0, 3, 5, 6, 7, 10]
        }
    }
}

/// パッド LED の色種別。
public enum LEDColor: Sendable {
    /// ルート音（紫）。
    case root
    /// スケール構成音（水色）。
    case member
    /// スケール外（白）。
    case outside
}

/// 指定キー・スケールの構成音集合（ルート + 各オフセットを mod12）。
public func scaleNotes(key: PitchClass, scale: Scale) -> Set<PitchClass> {
    Set(scale.offsets.map { PitchClass(key.value + $0) })
}

/// 単一パッドの色を決める。padNote%12 がルートなら root、構成音集合に含まれれば member、それ以外は outside。
public func padColor(padNote: Int, key: PitchClass, notes: Set<PitchClass>) -> LEDColor {
    let pc = PitchClass(padNote)
    if pc == key {
        return .root
    }
    if notes.contains(pc) {
        return .member
    }
    return .outside
}

/// padMap（パッドインデックス→ノート番号）の各パッドに色を割り当てる。
public func layout(state: State, padMap: [Int]) -> [(pad: Int, color: LEDColor)] {
    let notes = scaleNotes(key: state.key, scale: state.scale)
    return padMap.enumerated().map { index, note in
        (pad: index, color: padColor(padNote: note, key: state.key, notes: notes))
    }
}
