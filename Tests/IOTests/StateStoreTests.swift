import Core
import Foundation
import Testing

@testable import IO

@Suite("StateStore")
struct StateStoreTests {
    /// テスト毎にユニークな一時 DB パスを作り、ブロック実行後に後始末する。
    private func withTempStore<T>(_ body: (StateStore) throws -> T) rethrows -> T {
        let dir = NSTemporaryDirectory()
        let unique = "mf64-test-\(UUID().uuidString).sqlite"
        let path = (dir as NSString).appendingPathComponent(unique)
        defer {
            try? FileManager.default.removeItem(atPath: path)
            // SQLite の WAL/journal 等の副生成物も掃除する。
            try? FileManager.default.removeItem(atPath: path + "-wal")
            try? FileManager.default.removeItem(atPath: path + "-shm")
            try? FileManager.default.removeItem(atPath: path + "-journal")
        }
        return try body(StateStore(path: path))
    }

    @Test("初回 load はデフォルト C/Major を返す")
    func initialLoadDefaults() throws {
        try withTempStore { store in
            let state = try store.load()
            #expect(state.key == PitchClass(0))
            #expect(state.scale == .major)
        }
    }

    @Test("save した状態が load で一致する")
    func roundTrip() throws {
        try withTempStore { store in
            let saved = State(key: PitchClass(7), scale: .dorian)
            try store.save(saved)
            let loaded = try store.load()
            #expect(loaded == saved)
        }
    }

    @Test("save は 1 行を上書きする（複数回 save で最後が残る）")
    func saveOverwrites() throws {
        try withTempStore { store in
            try store.save(State(key: PitchClass(2), scale: .blues))
            try store.save(State(key: PitchClass(9), scale: .minorPentatonic))
            let loaded = try store.load()
            #expect(loaded == State(key: PitchClass(9), scale: .minorPentatonic))
        }
    }

    @Test("全スケールがラウンドトリップで復元される")
    func allScalesRoundTrip() throws {
        for scale in Scale.allCases {
            try withTempStore { store in
                let saved = State(key: PitchClass(5), scale: scale)
                try store.save(saved)
                #expect(try store.load() == saved)
            }
        }
    }

    @Test("初回 loadSettings は default を投入して返す")
    func initialLoadSettingsDefaults() throws {
        try withTempStore { store in
            let loaded = try store.loadSettings()
            #expect(loaded == Settings.default)
        }
    }

    @Test("saveSettings した設定が loadSettings で一致する")
    func settingsRoundTrip() throws {
        try withTempStore { store in
            let saved = Settings(midiChannel: 7, colorRoot: 100, colorMember: 50, colorOutside: 0)
            try store.saveSettings(saved)
            let loaded = try store.loadSettings()
            #expect(loaded == saved)
        }
    }

    @Test("saveSettings は 1 行を上書きする")
    func settingsOverwrites() throws {
        try withTempStore { store in
            try store.saveSettings(
                Settings(midiChannel: 3, colorRoot: 1, colorMember: 2, colorOutside: 3)
            )
            let last = Settings(midiChannel: 9, colorRoot: 4, colorMember: 5, colorOutside: 6)
            try store.saveSettings(last)
            let loaded = try store.loadSettings()
            #expect(loaded == last)
        }
    }

    @Test("settings と state は同一 DB で独立に保持される")
    func settingsAndStateCoexist() throws {
        try withTempStore { store in
            try store.save(State(key: PitchClass(7), scale: .dorian))
            let savedSettings = Settings(
                midiChannel: 5,
                colorRoot: 10,
                colorMember: 20,
                colorOutside: 30
            )
            try store.saveSettings(savedSettings)
            let loadedState = try store.load()
            let loadedSettings = try store.loadSettings()
            #expect(loadedState == State(key: PitchClass(7), scale: .dorian))
            #expect(loadedSettings == savedSettings)
        }
    }

    @Test("色境界値 0/127 がラウンドトリップで保持される")
    func settingsColorBoundariesRoundTrip() throws {
        try withTempStore { store in
            let saved = Settings(midiChannel: 1, colorRoot: 0, colorMember: 127, colorOutside: 64)
            try store.saveSettings(saved)
            let loaded = try store.loadSettings()
            #expect(loaded == saved)
        }
    }

    @Test("明示 path は MF64_DB_PATH より優先され、未指定なら環境変数を採用する")
    func explicitPathOverridesEnv() {
        setenv("MF64_DB_PATH", "/tmp/from-env.sqlite", 1)
        defer { unsetenv("MF64_DB_PATH") }
        // 明示 path があれば環境変数を無視する。
        #expect(StateStore(path: "/tmp/explicit.sqlite").path == "/tmp/explicit.sqlite")
        // path 未指定なら環境変数を採用する。
        #expect(StateStore(path: nil).path == "/tmp/from-env.sqlite")
    }
}
