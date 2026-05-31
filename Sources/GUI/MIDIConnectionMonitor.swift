import IO
import SwiftUI

/// MF64 の接続状態を 0.5 秒ポーリングで保持する。`isMF64Connected` を読むだけで送信はしない。
///
/// `.task(monitor.poll)` で View 寿命に紐づけて使う。`isConnected` の変化で再描画される。
@MainActor
final class MIDIConnectionMonitor: ObservableObject {
    @Published private(set) var isConnected = false

    /// 接続状態を判定する関数。テスト/プレビューで差し替え可能。
    private let probe: () -> Bool

    init(probe: @escaping () -> Bool = { isMF64Connected() }) {
        self.probe = probe
    }

    /// View 寿命の単一ループ。0.5 秒ごとに接続状態を読み直す。
    func poll() async {
        while !Task.isCancelled {
            let connected = probe()
            if connected != isConnected {
                isConnected = connected
            }
            try? await Task.sleep(for: .seconds(0.5))
        }
    }
}
