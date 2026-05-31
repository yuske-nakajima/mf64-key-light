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

/// 1 ウィンドウに「キー/スケール操作 + ライト配色」「コマンドカタログ」を並べる。
///
/// ピッカーは現在状態そのものを操作する。変更すると DB に保存され、グリッドが追従する。
/// CLI/ショートカットでの変更も 0.5 秒ポーリングでピッカー/グリッドに反映する（双方向）。
struct ContentView: View {
    @SwiftUI.State private var key = PitchClass(0)
    @SwiftUI.State private var scale: Scale = .major
    @SwiftUI.State private var settings: IO.Settings = .default

    private let store = StateStore()

    /// ピッカー用バインディング。set でのみ保存し、ポーリングの代入では保存しない。
    private var keyBinding: Binding<PitchClass> {
        Binding(get: { key }, set: { persist(key: $0, scale: scale) })
    }
    private var scaleBinding: Binding<Scale> {
        Binding(get: { scale }, set: { persist(key: key, scale: $0) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                controlSection
                Divider()
                midiSettingsSection
                Divider()
                CommandCatalogView()
            }
            .padding(24)
        }
        .task {
            // View 寿命に紐づく単一ループ。CLI 等の外部変更をピッカー/グリッド/設定へ取り込む。
            while !Task.isCancelled {
                if let s = try? store.load() {
                    key = s.key
                    scale = s.scale
                }
                if let loaded = try? store.loadSettings() {
                    settings = loaded
                }
                try? await Task.sleep(for: .seconds(0.5))
            }
        }
    }

    /// MIDI チャンネルと 3 色 velocity を編集する。編集ごとに DB へ保存する。
    private var midiSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MIDI 設定").font(.headline)
            Text("参考値: channel=2 / 紫(root)=54 / 水色(member)=36 / 白(outside)=3")
                .font(.caption)
                .foregroundStyle(.secondary)
            Stepper(
                "MIDI チャンネル: \(settings.midiChannel)",
                value: channelBinding,
                in: 1...16
            )
            .frame(width: 240)
            colorStepper("紫 (root)", value: \.colorRoot)
            colorStepper("水色 (member)", value: \.colorMember)
            colorStepper("白 (outside)", value: \.colorOutside)
        }
    }

    private var channelBinding: Binding<Int> {
        Binding(
            get: { settings.midiChannel },
            set: { newValue in
                var updated = settings
                updated.midiChannel = newValue
                settings = updated
                try? store.saveSettings(updated)
            }
        )
    }

    /// 1 色分の velocity Stepper（0..127）を作る。
    private func colorStepper(
        _ label: String,
        value keyPath: WritableKeyPath<IO.Settings, UInt8>
    ) -> some View {
        let binding = Binding<Int>(
            get: { Int(settings[keyPath: keyPath]) },
            set: { newValue in
                var updated = settings
                updated[keyPath: keyPath] = UInt8(clamping: newValue)
                settings = updated
                try? store.saveSettings(updated)
            }
        )
        return Stepper("\(label): \(Int(settings[keyPath: keyPath]))", value: binding, in: 0...127)
            .frame(width: 240)
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("キー / スケール").font(.headline)
            HStack(spacing: 16) {
                Picker("Key", selection: keyBinding) {
                    ForEach(0..<12, id: \.self) { v in
                        Text(KeyNames.names[v]).tag(PitchClass(v))
                    }
                }
                .frame(width: 140)
                Picker("Scale", selection: scaleBinding) {
                    ForEach(Scale.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .frame(width: 220)
            }
            PadGridView(state: Core.State(key: key, scale: scale))
        }
    }

    /// 状態を更新して DB に保存する（ピッカー操作の唯一の書き込み経路）。
    private func persist(key newKey: PitchClass, scale newScale: Scale) {
        key = newKey
        scale = newScale
        try? store.save(Core.State(key: newKey, scale: newScale))
    }
}
