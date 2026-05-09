import Foundation
import GRDB

enum StorageSchema {
    static func prepare(in databaseQueue: DatabaseQueue) async throws {
        try await databaseQueue.writeWithoutTransaction { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            try db.execute(sql: "PRAGMA synchronous = NORMAL")
        }

        try await databaseQueue.write { db in
            for statement in createTableStatements {
                try db.execute(sql: statement)
            }

            for statement in createIndexStatements {
                try db.execute(sql: statement)
            }

            try ensureColumnExists(name: "note", definition: "TEXT", in: "page_memory", db: db)
            try ensureColumnExists(name: "is_pinned", definition: "INTEGER NOT NULL DEFAULT 0", in: "page_memory", db: db)
            try ensureColumnExists(name: "group_name", definition: "TEXT", in: "workspace_tabs", db: db)
            try ensureColumnExists(name: "group_color_key", definition: "TEXT", in: "workspace_tabs", db: db)
        }
    }

    nonisolated private static let createTableStatements = [
        """
        CREATE TABLE IF NOT EXISTS history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            title TEXT,
            timestamp INTEGER NOT NULL,
            visit_count INTEGER DEFAULT 1,
            last_visit INTEGER
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            title TEXT NOT NULL,
            folder TEXT DEFAULT 'Default',
            created_at INTEGER NOT NULL,
            modified_at INTEGER NOT NULL
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS search_index (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_id INTEGER NOT NULL,
            source_type TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            url TEXT NOT NULL,
            indexed_at INTEGER NOT NULL
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS workspaces (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            title TEXT NOT NULL,
            purpose TEXT,
            summary TEXT,
            status TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            last_opened_at INTEGER
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS workspace_tabs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workspace_id INTEGER NOT NULL,
            url TEXT NOT NULL,
            title TEXT,
            favicon_url TEXT,
            note TEXT,
            group_name TEXT,
            group_color_key TEXT,
            added_at INTEGER NOT NULL,
            last_seen_at INTEGER,
            FOREIGN KEY(workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS page_memory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            normalized_url TEXT NOT NULL UNIQUE,
            title TEXT,
            host TEXT,
            summary TEXT,
            takeaway TEXT,
            keywords TEXT,
            note TEXT,
            is_pinned INTEGER NOT NULL DEFAULT 0,
            last_visited_at INTEGER NOT NULL,
            visit_count INTEGER DEFAULT 1
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS compare_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workspace_id INTEGER,
            title TEXT,
            source_urls TEXT NOT NULL,
            result_markdown TEXT NOT NULL,
            created_at INTEGER NOT NULL
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS watch_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            url TEXT NOT NULL,
            title TEXT,
            watch_type TEXT NOT NULL,
            prompt TEXT,
            status TEXT NOT NULL,
            last_checked_at INTEGER,
            created_at INTEGER NOT NULL
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS watch_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            watch_rule_id INTEGER NOT NULL,
            content_hash TEXT NOT NULL,
            summary TEXT,
            change_summary TEXT,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(watch_rule_id) REFERENCES watch_rules(id) ON DELETE CASCADE
        )
        """
    ]

    nonisolated private static let createIndexStatements = [
        "CREATE INDEX IF NOT EXISTS idx_history_timestamp ON history(timestamp DESC)",
        "CREATE INDEX IF NOT EXISTS idx_history_url ON history(url)",
        "CREATE INDEX IF NOT EXISTS idx_bookmarks_folder ON bookmarks(folder)",
        "CREATE INDEX IF NOT EXISTS idx_search_source ON search_index(source_id, source_type)",
        "CREATE INDEX IF NOT EXISTS idx_workspaces_updated_at ON workspaces(updated_at DESC)",
        "CREATE INDEX IF NOT EXISTS idx_workspace_tabs_workspace_id ON workspace_tabs(workspace_id)",
        "CREATE INDEX IF NOT EXISTS idx_page_memory_last_visited_at ON page_memory(last_visited_at DESC)",
        "CREATE INDEX IF NOT EXISTS idx_compare_sessions_created_at ON compare_sessions(created_at DESC)",
        "CREATE INDEX IF NOT EXISTS idx_watch_rules_status ON watch_rules(status)",
        "CREATE INDEX IF NOT EXISTS idx_watch_snapshots_watch_rule_id ON watch_snapshots(watch_rule_id)"
    ]

    nonisolated private static func ensureColumnExists(
        name: String,
        definition: String,
        in table: String,
        db: Database
    ) throws {
        let columns = try db.columns(in: table).map(\.name)
        guard !columns.contains(name) else { return }
        try db.execute(sql: "ALTER TABLE \(table) ADD COLUMN \(name) \(definition)")
    }
}
