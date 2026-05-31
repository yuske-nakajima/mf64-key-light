import Core
import IO
import SwiftUI

@main
struct SettingsApp: App {
    var body: some Scene {
        WindowGroup("MF64 Key Light") {
            ContentView()
                .frame(minWidth: 720, minHeight: 560)
        }
    }
}

/// 1 ウィンドウに「現在状態」「ライト配色」「コマンドカタログ」を並べる。
struct ContentView: View {
    /// StateStore をポーリングして得た現在状態（CLI/ショートカット更新に追従）。
    @SwiftUI.State private var liveState: Core.State?

    private let store = StateStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                currentStateSection
                Divider()
                colorSection
                Divider()
                CommandCatalogView()
            }
            .padding(24)
        }
        .task {
            // View 寿命に紐づく単一ループ。再生成ごとに作り直される stored Timer と違い安定して回る。
            while !Task.isCancelled {
                liveState = try? store.load()
                try? await Task.sleep(for: .seconds(0.5))
            }
        }
    }

    private var currentStateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("現在状態（DB ポーリング）").font(.headline)
            if let s = liveState {
                Text("key=\(KeyNames.name(s.key))  scale=\(s.scale.rawValue)")
                    .font(.system(.body, design: .monospaced))
            } else {
                Text("読み込み中…").foregroundStyle(.secondary)
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ライト配色（8×8）").font(.headline)
            if let s = liveState {
                PadGridView(state: s)
            } else {
                Text("読み込み中…").foregroundStyle(.secondary)
            }
        }
    }
}
