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
    /// StateStore をポーリングして得た現在状態（CLI/ショートカット更新に追従）。
    @SwiftUI.State private var liveState: Core.State?
    /// オンのときグリッドは現在状態に追従。オフで手動プレビュー。
    @SwiftUI.State private var followLive = true
    /// 手動プレビュー対象のキー/スケール。
    @SwiftUI.State private var previewKey = PitchClass(0)
    @SwiftUI.State private var previewScale: Scale = .major

    private let store = StateStore()

    /// グリッドに描く状態。追従オン かつ 現在状態あり ならそれを、無ければ手動ピッカーを使う。
    private var displayState: Core.State {
        if followLive, let s = liveState {
            return s
        }
        return Core.State(key: previewKey, scale: previewScale)
    }

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
        .task {
            // View 寿命に紐づく単一ループ。再生成ごとに作り直される stored Timer と違い安定して回る。
            while !Task.isCancelled {
                let loaded = try? store.load()
                liveState = loaded
                // 追従中はピッカーも現在状態に合わせ、トグルを切り替えた瞬間から連続させる。
                if followLive, let s = loaded {
                    previewKey = s.key
                    previewScale = s.scale
                }
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

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("配色プレビュー（8×8）").font(.headline)
            Toggle("現在状態に追従（オフで手動プレビュー）", isOn: $followLive)
                .toggleStyle(.switch)
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
            .disabled(followLive)
            PadGridView(state: displayState)
        }
    }
}
