import Core
import Foundation
import SQLite3

/// 現在のキー/スケール 1 セットを SQLite に永続化する I/O 境界。
///
/// 1 行テーブル `state` に `current_key`(PitchClass.value) と `current_scale`(Scale.rawValue)
/// を保持する。初回（行が無い）はデフォルト C / Major を投入して返す。
public struct StateStore {
    /// DB ファイルパス。`MF64_DB_PATH` があればそれを優先、無ければ Application Support 配下。
    public let path: String

    /// SQLite が文字列バインドのコピーを取るための SQLITE_TRANSIENT(-1) 相当。
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    public init(path: String? = nil) {
        if let path {
            self.path = path
        } else if let env = ProcessInfo.processInfo.environment["MF64_DB_PATH"] {
            self.path = env
        } else {
            self.path = StateStore.defaultPath()
        }
    }

    /// `~/Library/Application Support/mf64-key-light/state.sqlite`。
    private static func defaultPath() -> String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first
        let base =
            appSupport
            ?? URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support")
        let dir = base.appendingPathComponent("mf64-key-light")
        return dir.appendingPathComponent("state.sqlite").path
    }

    /// DB を開き、テーブルを用意し、現在状態を返す。行が無ければデフォルトを投入して返す。
    public func load() throws -> State {
        let db = try open()
        defer { sqlite3_close(db) }
        try ensureSchema(db)

        let sql = "SELECT current_key, current_scale FROM state WHERE id = 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StateStoreError.sqlite(message(db))
        }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            let keyValue = Int(sqlite3_column_int(stmt, 0))
            let rawScale = String(cString: sqlite3_column_text(stmt, 1))
            // 未知の rawValue はデフォルト(.major)へフォールバックする。
            let scale = Scale(rawValue: rawScale) ?? .major
            return State(key: PitchClass(keyValue), scale: scale)
        }

        // 行が無い初回はデフォルトを投入して返す。
        let initial = State(key: PitchClass(0), scale: .major)
        try write(db, initial)
        return initial
    }

    /// 現在状態を 1 行に書き込む（UPSERT）。
    public func save(_ state: State) throws {
        let db = try open()
        defer { sqlite3_close(db) }
        try ensureSchema(db)
        try write(db, state)
    }

    // MARK: - private

    private func open() throws -> OpaquePointer {
        // 既定パスのときのみ親ディレクトリを作る。MF64_DB_PATH（テストの一時ファイル）は呼び出し側が用意する前提。
        let dir = (path as NSString).deletingLastPathComponent
        if !dir.isEmpty {
            try? FileManager.default.createDirectory(
                atPath: dir,
                withIntermediateDirectories: true
            )
        }
        var db: OpaquePointer?
        guard sqlite3_open(path, &db) == SQLITE_OK, let db else {
            let msg = db.map(message) ?? "sqlite3_open failed"
            if let db { sqlite3_close(db) }
            throw StateStoreError.sqlite(msg)
        }
        return db
    }

    private func ensureSchema(_ db: OpaquePointer) throws {
        let sql = """
            CREATE TABLE IF NOT EXISTS state (
                id INTEGER PRIMARY KEY CHECK(id = 1),
                current_key INTEGER NOT NULL,
                current_scale TEXT NOT NULL
            );
            """
        try exec(db, sql)
    }

    private func write(_ db: OpaquePointer, _ state: State) throws {
        let sql = """
            INSERT INTO state (id, current_key, current_scale) VALUES (1, ?, ?)
            ON CONFLICT(id) DO UPDATE SET current_key = excluded.current_key,
                current_scale = excluded.current_scale;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StateStoreError.sqlite(message(db))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(state.key.value))
        sqlite3_bind_text(stmt, 2, state.scale.rawValue, -1, StateStore.transient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw StateStoreError.sqlite(message(db))
        }
    }

    private func exec(_ db: OpaquePointer, _ sql: String) throws {
        var errmsg: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errmsg) == SQLITE_OK else {
            let msg = errmsg.map { String(cString: $0) } ?? "sqlite3_exec failed"
            sqlite3_free(errmsg)
            throw StateStoreError.sqlite(msg)
        }
    }

    private func message(_ db: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(db))
    }
}

/// StateStore の I/O 失敗。
public enum StateStoreError: Error, Equatable, Sendable {
    case sqlite(String)
}
