import Core
import IO
import SwiftUI

@main
struct SettingsApp: App {
    init() {
        // 同梱フォントを起動時に一度だけ登録する。
        FontRegistration.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup("MF64 Key Light") {
            ContentView()
                .frame(minWidth: 980)
        }
        // ウィンドウを内容ぴったりに収め、padding がそのまま上下左右の余白になるようにする。
        .windowResizability(.contentSize)
    }
}

/// ContentView が表示中のページ。中身をフルスワップで切り替える。
enum Page {
    /// HEADER + MAIN（KEY LIGHT）。下部にサブページへのナビを置く。
    case main
    /// MIDI OUTPUT セクション単独。
    case midiOutput
    /// SHORTCUT COMMANDS セクション単独。
    case shortcut
}

/// ウィンドウ内容を `Page` 単位でフルスワップする（縦スクロールはしない）。
///
/// 各操作は現在状態そのものを編集する。変更すると DB に保存され、実機とグリッドが追従する。
/// CLI/ショートカットでの変更も 0.5 秒ポーリングで各表示に反映する（双方向同期）。
/// 書き込みは set 経路（persist / persistSettings）のみで、ポーリング代入は get 側の更新のみ。
/// State はページをまたいで ContentView が保持するため、ページ切替で失われない。
struct ContentView: View {
    @SwiftUI.State private var key = PitchClass(0)
    @SwiftUI.State private var scale: Scale = .major
    @SwiftUI.State private var settings: IO.Settings = .default

    /// 表示中のページ。ナビ/戻るボタンで切り替える。
    @SwiftUI.State private var page: Page = .main

    private let store = StateStore()

    /// MF64 接続状態のポーリング監視（ヘッダーのステータス表示用）。
    @StateObject private var connection = MIDIConnectionMonitor()

    var body: some View {
        pageContent
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(PlateBackground().ignoresSafeArea())
            .overlay(GrainOverlay().ignoresSafeArea())
            .task {
                // View 寿命に紐づく単一ループ。CLI 等の外部変更をグリッド/設定へ取り込む。
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
            .task {
                // 接続状態を別ループでポーリングする（送信はしない）。
                await connection.poll()
            }
    }

    // MARK: - ページ本体

    /// 現在の `page` に応じた中身。各ページはウィンドウに収める（スクロールしない）。
    @ViewBuilder private var pageContent: some View {
        switch page {
        case .main: mainPage
        case .midiOutput: midiOutputPage
        case .shortcut: shortcutPage
        }
    }

    /// MAIN ページ。HEADER + MAIN セクション + サブページへのナビ。
    private var mainPage: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            HeaderView(isConnected: connection.isConnected)
            MainSection(
                key: key,
                scale: scale,
                onRootChange: { persist(key: $0, scale: scale) },
                onScaleChange: { persist(key: key, scale: $0) }
            )
            Spacer(minLength: 0)
            jumpNav
        }
    }

    /// MAIN 下部のページ遷移ナビ。サブページを差し替え表示する。
    private var jumpNav: some View {
        HStack(spacing: DesignTokens.Spacing.element) {
            SkeuoButton(action: { page = .midiOutput }) {
                Text("MIDI OUTPUT")
            }
            SkeuoButton(action: { page = .shortcut }) {
                Text("SHORTCUT COMMANDS")
            }
            Spacer(minLength: 0)
        }
    }

    /// MIDI OUTPUT ページ。戻る + 見出し + MidiOutputSection。
    private var midiOutputPage: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            subpageHeader("MIDI OUTPUT")
            MidiOutputSection(
                settings: settings,
                isConnected: connection.isConnected,
                onSettingsChange: persistSettings
            )
            Spacer(minLength: 0)
        }
    }

    /// SHORTCUT COMMANDS ページ。戻る + 見出し + CommandCatalogView。
    private var shortcutPage: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            subpageHeader("SHORTCUT COMMANDS")
            CommandCatalogView()
            Spacer(minLength: 0)
        }
    }

    /// サブページ上部の「←」戻るボタン + セクション見出し。
    private func subpageHeader(_ title: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.element) {
            SkeuoButton(action: { page = .main }) {
                Text("←")
            }
            .accessibilityLabel("back")
            EngravedText(title, font: .oswald(20), color: DesignTokens.Engrave.strong)
            Spacer(minLength: 0)
        }
    }

    /// 設定を更新して DB に保存し、実機へ送信する（MIDI OUTPUT ノブ操作の唯一の書き込み経路）。
    private func persistSettings(_ updated: IO.Settings) {
        settings = updated
        try? store.saveSettings(updated)
        pushToDevice(key: key, scale: scale, settings: updated)
    }

    /// 状態を更新して DB に保存し、実機へ送信する（ROOT/SCALE 操作の唯一の書き込み経路）。
    private func persist(key newKey: PitchClass, scale newScale: Scale) {
        key = newKey
        scale = newScale
        try? store.save(Core.State(key: newKey, scale: newScale))
        pushToDevice(key: newKey, scale: newScale, settings: settings)
    }

    /// 現在のキー/スケール/設定で実機へ送信する。MF64 が接続されていなければ何もしない。
    private func pushToDevice(key: PitchClass, scale: Scale, settings: IO.Settings) {
        guard let sender = try? CoreMIDISender(settings: settings) else { return }
        let state = Core.State(key: key, scale: scale)
        let pads = layout(state: state, padMap: Devices.defaultPadMap)
        try? sender.send(pads, padMap: Devices.defaultPadMap)
    }
}
