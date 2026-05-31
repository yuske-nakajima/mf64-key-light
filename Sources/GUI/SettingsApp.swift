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

/// 1 ウィンドウに「現在状態」「配色プレビュー」「コマンドカタログ」を並べる。
struct ContentView: View {
    /// プレビュー対象のキー/スケール。画面で選んで配色を確認する。
    @SwiftUI.State private var previewKey = PitchClass(0)
    @SwiftUI.State private var previewScale: Scale = .major

    /// StateStore をポーリングして得た現在状態（CLI 更新に追従）。
    @SwiftUI.State private var liveState: Core.State?

    /// 1 秒ごとに DB を読む。
    private let pollTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let store = StateStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                currentStateSection
                Divider()
                previewSection
                Divider()
                CommandCatalogView()
            }
            .padding(24)
        }
        .onReceive(pollTimer) { _ in
            liveState = try? store.load()
        }
        .onAppear {
            liveState = try? store.load()
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

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("配色プレビュー（8×8）").font(.headline)
            HStack(spacing: 16) {
                Picker("Key", selection: $previewKey) {
                    ForEach(0..<12, id: \.self) { v in
                        Text(KeyNames.names[v]).tag(PitchClass(v))
                    }
                }
                .frame(width: 140)
                Picker("Scale", selection: $previewScale) {
                    ForEach(Scale.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .frame(width: 220)
            }
            PadGridView(state: Core.State(key: previewKey, scale: previewScale))
        }
    }
}
