/// アプリの現在状態（キーとスケール）。
public struct State: Equatable, Sendable {
    public var key: PitchClass
    public var scale: Scale

    public init(key: PitchClass, scale: Scale) {
        self.key = key
        self.scale = scale
    }
}

/// 状態にコマンドを適用して新しい状態を返す純粋関数。完全指定と相対の分岐をここに集約する。
public func apply(_ state: State, _ command: Command) -> State {
    switch command {
    case .set(let key, let scale):
        // 指定された側だけ差し替え、nil の側は維持する。
        return State(key: key ?? state.key, scale: scale ?? state.scale)

    case .scaleStep(let direction):
        let cycle = Scale.cycle
        // cycle に必ず含まれる前提。万一見つからなければ状態を変えない。
        guard let i = cycle.firstIndex(of: state.scale) else { return state }
        let count = cycle.count
        let next: Int
        switch direction {
        case .up: next = (i + 1) % count
        case .down: next = (i - 1 + count) % count
        }
        return State(key: state.key, scale: cycle[next])

    case .rootStep(let direction):
        let delta = direction == .up ? 1 : -1
        return State(key: PitchClass(state.key.value + delta), scale: state.scale)
    }
}
