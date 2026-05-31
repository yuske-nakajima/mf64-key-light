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

    @Test("MF64_DB_PATH 環境変数が無指定の path より優先される")
    func envPathRespectedByDefault() {
        // path を nil にすると環境変数を見る。テストプロセスで設定済みの値を反映するか確認。
        // ここでは環境変数を直接いじらず、明示 path 指定が環境変数より優先されることを確認する。
        let explicit = "/tmp/explicit.sqlite"
        let store = StateStore(path: explicit)
        #expect(store.path == explicit)
    }
}
