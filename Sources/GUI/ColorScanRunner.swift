import Foundation
import IO

/// COLOR SCAN（velocity 順送り）を GUI 内で非同期実行する状態保持オブジェクト。
///
/// `colorscanSteps` で (note, velocity) 列を生成し、`CoreMIDISender` で 1 ステップずつ送る。
/// 実行中は現在 velocity を `currentVelocity` に反映し、再実行 / 停止で Task をキャンセルする。
/// 送信は try? でラップしてクラッシュさせない。MF64 未接続時は `start` が即終了する。
@MainActor
final class ColorScanRunner: ObservableObject {
    /// スキャン実行中か。ボタン表示の切替に使う。
    @Published private(set) var isScanning = false
    /// 直近に送った velocity（実行中のみ非 nil）。
    @Published private(set) var currentVelocity: UInt8?

    /// ステップ間隔（ミリ秒）。
    private let delayMilliseconds = 300

    private var task: Task<Void, Never>?

    /// 実行中なら停止、停止中なら開始する。
    func toggle(settings: IO.Settings) {
        if isScanning {
            stop()
        } else {
            start(settings: settings)
        }
    }

    /// 既定設定（note=colorscanDefaultNote, 0..127）でスキャンを開始する。
    /// MF64 未接続なら sender 生成に失敗し、何も送らず終了する。
    func start(settings: IO.Settings) {
        guard !isScanning else { return }
        guard let sender = try? CoreMIDISender(settings: settings) else { return }

        let config = ColorscanConfig(
            note: Devices.colorscanDefaultNote,
            from: 0,
            to: 127,
            delayMilliseconds: delayMilliseconds
        )
        let steps = colorscanSteps(config)
        guard !steps.isEmpty else { return }

        isScanning = true
        task = Task { [weak self] in
            for step in steps {
                if Task.isCancelled { break }
                try? sender.sendNoteOn(note: step.note, velocity: step.velocity)
                self?.currentVelocity = step.velocity
                try? await Task.sleep(for: .milliseconds(config.delayMilliseconds))
            }
            self?.finish()
        }
    }

    /// スキャンを停止する（Task キャンセル）。
    func stop() {
        task?.cancel()
        finish()
    }

    private func finish() {
        task = nil
        isScanning = false
        currentVelocity = nil
    }
}
