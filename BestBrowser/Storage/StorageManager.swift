import Foundation
import GRDB

@MainActor
class StorageManager: NSObject, ObservableObject {
    static let shared = StorageManager()

    private var dbQueue: DatabaseQueue?
    private let databaseURLOverride: URL?
    @Published var isInitialized = false

    init(databaseURL: URL? = nil) {
        self.databaseURLOverride = databaseURL
        super.init()
        Task {
            await initializeDatabase()
        }
    }

    private func initializeDatabase() async {
        do {
            let dbURL = try resolvedDatabaseURL()
            dbQueue = try DatabaseQueue(path: dbURL.path)

            try await dbQueue?.writeWithoutTransaction { db in
                try db.execute(sql: "PRAGMA journal_mode = WAL")
                try db.execute(sql: "PRAGMA foreign_keys = ON")
                try db.execute(sql: "PRAGMA synchronous = NORMAL")
            }

            try await createTables()
            isInitialized = true
        } catch {
            print("❌ Database initialization failed: \(error)")
        }
    }

    private func createTables() async throws {
        guard let db = dbQueue else { return }

        try await db.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    url TEXT NOT NULL,
                    title TEXT,
                    timestamp INTEGER NOT NULL,
                    visit_count INTEGER DEFAULT 1,
                    last_visit INTEGER
                )
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS bookmarks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    url TEXT NOT NULL,
                    title TEXT NOT NULL,
                    folder TEXT DEFAULT 'Default',
                    created_at INTEGER NOT NULL,
                    modified_at INTEGER NOT NULL
                )
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS settings (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL,
                    updated_at INTEGER NOT NULL
                )
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS search_index (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    source_id INTEGER NOT NULL,
                    source_type TEXT NOT NULL,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL,
                    url TEXT NOT NULL,
                    indexed_at INTEGER NOT NULL
                )
                """)

            try db.execute(sql: """
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
                """)

            try db.execute(sql: """
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
                """)

            try db.execute(sql: """
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
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS compare_sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    workspace_id INTEGER,
                    title TEXT,
                    source_urls TEXT NOT NULL,
                    result_markdown TEXT NOT NULL,
                    created_at INTEGER NOT NULL
                )
                """)

            try db.execute(sql: """
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
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS watch_snapshots (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    watch_rule_id INTEGER NOT NULL,
                    content_hash TEXT NOT NULL,
                    summary TEXT,
                    change_summary TEXT,
                    created_at INTEGER NOT NULL,
                    FOREIGN KEY(watch_rule_id) REFERENCES watch_rules(id) ON DELETE CASCADE
                )
                """)

            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_history_timestamp ON history(timestamp DESC)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_history_url ON history(url)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_bookmarks_folder ON bookmarks(folder)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_search_source ON search_index(source_id, source_type)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_workspaces_updated_at ON workspaces(updated_at DESC)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_workspace_tabs_workspace_id ON workspace_tabs(workspace_id)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_page_memory_last_visited_at ON page_memory(last_visited_at DESC)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_compare_sessions_created_at ON compare_sessions(created_at DESC)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_watch_rules_status ON watch_rules(status)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_watch_snapshots_watch_rule_id ON watch_snapshots(watch_rule_id)")

            try Self.ensureColumnExists(name: "note", definition: "TEXT", in: "page_memory", db: db)
            try Self.ensureColumnExists(name: "is_pinned", definition: "INTEGER NOT NULL DEFAULT 0", in: "page_memory", db: db)
            try Self.ensureColumnExists(name: "group_name", definition: "TEXT", in: "workspace_tabs", db: db)
            try Self.ensureColumnExists(name: "group_color_key", definition: "TEXT", in: "workspace_tabs", db: db)
        }
    }

    private func resolvedDatabaseURL() throws -> URL {
        if let databaseURLOverride {
            let parent = databaseURLOverride.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            return databaseURLOverride
        }

        let fileURL = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("com.bestbrowser")

        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        return fileURL.appendingPathComponent("bestbrowser.db")
    }

    nonisolated private static func ensureColumnExists(name: String, definition: String, in table: String, db: Database) throws {
        let columns = try db.columns(in: table).map(\.name)
        guard !columns.contains(name) else { return }
        try db.execute(sql: "ALTER TABLE \(table) ADD COLUMN \(name) \(definition)")
    }

    func waitUntilInitialized(timeoutNanoseconds: UInt64 = 5_000_000_000) async throws {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while !isInitialized {
            if DispatchTime.now().uptimeNanoseconds > deadline {
                throw StorageError.databaseNotInitialized
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    func addHistory(_ url: String, title: String) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            let oneHourAgo = Date().addingTimeInterval(-3600)
            if let existing = try HistoryEntry
                .filter(Column("url") == url && Column("timestamp") > oneHourAgo)
                .fetchOne(db) {
                var updated = existing
                updated.visitCount += 1
                updated.lastVisit = Date()
                try updated.update(db)
            } else {
                let entry = HistoryEntry(
                    id: nil,
                    url: url,
                    title: title,
                    timestamp: Date(),
                    visitCount: 1,
                    lastVisit: Date()
                )
                try entry.insert(db)
            }
        }
    }

    func getHistory(limit: Int = 100) async throws -> [HistoryEntry] {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            try HistoryEntry
                .order(Column("timestamp").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func searchHistory(_ query: String) async throws -> [HistoryEntry] {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            try HistoryEntry
                .filter(Column("url").like("%\(query)%") || Column("title").like("%\(query)%"))
                .order(Column("timestamp").desc)
                .fetchAll(db)
        }
    }

    func clearHistory() async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            try db.execute(sql: "DELETE FROM history")
            try db.execute(sql: "DELETE FROM search_index WHERE source_type = 'history'")
        }
    }

    func deleteHistoryEntry(id: Int64) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            _ = try HistoryEntry.deleteOne(db, key: id)
        }
    }

    func clearSearchIndex() async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            try db.execute(sql: "DELETE FROM search_index")
        }
    }

    func addBookmark(url: String, title: String, folder: String = "Default") async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            let bookmark = Bookmark(
                id: nil,
                url: url,
                title: title,
                folder: folder,
                createdAt: Date(),
                modifiedAt: Date()
            )
            try bookmark.insert(db)
        }
    }

    func getBookmarks(folder: String? = nil) async throws -> [Bookmark] {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            if let folder = folder {
                return try Bookmark
                    .filter(Column("folder") == folder)
                    .order(Column("created_at").desc)
                    .fetchAll(db)
            } else {
                return try Bookmark
                    .order(Column("created_at").desc)
                    .fetchAll(db)
            }
        }
    }

    func deleteBookmark(id: Int64) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            _ = try Bookmark.deleteOne(db, key: id)
        }
    }

    func setSetting(_ key: String, value: String) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            let setting = StorageSetting(key: key, value: value, updatedAt: Date())
            try setting.upsert(db)
        }
    }

    func getSetting(_ key: String) async throws -> String? {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            try StorageSetting.fetchOne(db, key: key)?.value
        }
    }

    func indexSearch(title: String, content: String, url: String, sourceId: Int64, sourceType: String) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            let entry = SearchIndexEntry(
                id: nil,
                sourceId: sourceId,
                sourceType: sourceType,
                title: title,
                content: content,
                url: url,
                indexedAt: Date()
            )
            try entry.insert(db)
        }
    }

    func searchAll(_ query: String, limit: Int = 50) async throws -> SearchResults {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            let indexResults = try SearchIndexEntry
                .filter(Column("title").like("%\(query)%") || Column("content").like("%\(query)%"))
                .order(Column("indexed_at").desc)
                .limit(limit)
                .fetchAll(db)

            let history = try HistoryEntry
                .filter(Column("title").like("%\(query)%") || Column("url").like("%\(query)%"))
                .order(Column("timestamp").desc)
                .limit(limit)
                .fetchAll(db)

            let memories = try PageMemory
                .filter(
                    Column("title").like("%\(query)%") ||
                    Column("summary").like("%\(query)%") ||
                    Column("takeaway").like("%\(query)%") ||
                    Column("note").like("%\(query)%") ||
                    Column("keywords").like("%\(query)%") ||
                    Column("url").like("%\(query)%")
                )
                .order(Column("is_pinned").desc, Column("last_visited_at").desc)
                .limit(limit)
                .fetchAll(db)

            return SearchResults(indexResults: indexResults, historyResults: history, memoryResults: memories)
        }
    }

    func createWorkspace(
        title: String,
        purpose: String?,
        summary: String?,
        status: WorkspaceStatus
    ) async throws -> Workspace {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.write { db in
            let createdAt = Date()
            try db.execute(
                sql: """
                INSERT INTO workspaces (uuid, title, purpose, summary, status, created_at, updated_at, last_opened_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    UUID().uuidString,
                    title,
                    purpose,
                    summary,
                    status.rawValue,
                    createdAt,
                    createdAt,
                    nil as Date?
                ]
            )

            return Workspace(
                id: db.lastInsertedRowID,
                title: title,
                purpose: purpose,
                summary: summary,
                status: status,
                createdAt: createdAt,
                updatedAt: createdAt,
                lastOpenedAt: nil
            )
        }
    }

    func getWorkspaces(limit: Int = 100) async throws -> [Workspace] {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            try Workspace
                .order(Column("updated_at").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func updateWorkspace(id: Int64, title: String, purpose: String?, summary: String?) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            try db.execute(
                sql: """
                UPDATE workspaces
                SET title = ?, purpose = ?, summary = ?, updated_at = ?
                WHERE id = ?
                """,
                arguments: [title, purpose, summary, Date(), id]
            )
        }
    }

    func deleteWorkspace(id: Int64) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            _ = try Workspace.deleteOne(db, key: id)
        }
    }

    func getWorkspaceTabs(workspaceId: Int64) async throws -> [WorkspaceTab] {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            try WorkspaceTab
                .filter(Column("workspace_id") == workspaceId)
                .order(Column("added_at").asc)
                .fetchAll(db)
        }
    }

    func replaceWorkspaceTabs(workspaceId: Int64, tabs: [WorkspaceTab]) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            try db.execute(
                sql: "DELETE FROM workspace_tabs WHERE workspace_id = ?",
                arguments: [workspaceId]
            )

            for var tab in tabs {
                tab.workspaceId = workspaceId
                try tab.insert(db)
            }

            try db.execute(
                sql: "UPDATE workspaces SET updated_at = ? WHERE id = ?",
                arguments: [Date(), workspaceId]
            )
        }
    }

    func recordWorkspaceOpened(id: Int64) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            try db.execute(
                sql: """
                UPDATE workspaces
                SET last_opened_at = ?, updated_at = ?
                WHERE id = ?
                """,
                arguments: [Date(), Date(), id]
            )
        }
    }

    func upsertPageMemory(_ memory: PageMemory) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            if let existing = try PageMemory
                .filter(Column("normalized_url") == memory.normalizedUrl)
                .fetchOne(db) {
                try db.execute(
                    sql: """
                    UPDATE page_memory
                    SET url = ?, title = ?, host = ?, summary = ?, takeaway = ?, keywords = ?, note = COALESCE(note, ?), is_pinned = COALESCE(is_pinned, ?), last_visited_at = ?, visit_count = ?
                    WHERE id = ?
                    """,
                    arguments: [
                        memory.url,
                        memory.title,
                        memory.host,
                        memory.summary,
                        memory.takeaway,
                        memory.keywords,
                        memory.note,
                        memory.isPinned,
                        Date(),
                        existing.visitCount + 1,
                        existing.id ?? 0
                    ]
                )
            } else {
                let inserted = memory
                try inserted.insert(db)
            }
        }
    }

    func getPageMemories(limit: Int = 50) async throws -> [PageMemory] {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            try PageMemory
                .order(Column("is_pinned").desc, Column("last_visited_at").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func updatePageMemory(id: Int64, note: String?, isPinned: Bool) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            try db.execute(
                sql: """
                UPDATE page_memory
                SET note = ?, is_pinned = ?
                WHERE id = ?
                """,
                arguments: [note, isPinned, id]
            )
        }
    }

    func addCompareSession(title: String?, workspaceId: Int64?, sourceUrls: [String], resultMarkdown: String) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        let payload = try JSONEncoder().encode(sourceUrls)
        let payloadString = String(data: payload, encoding: .utf8) ?? "[]"

        try await db.write { db in
            try db.execute(
                sql: """
                INSERT INTO compare_sessions (workspace_id, title, source_urls, result_markdown, created_at)
                VALUES (?, ?, ?, ?, ?)
                """,
                arguments: [workspaceId, title, payloadString, resultMarkdown, Date()]
            )
        }
    }

    func getCompareSessions(limit: Int = 20) async throws -> [CompareSession] {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        struct CompareRow: FetchableRecord, Decodable {
            let id: Int64
            let workspaceId: Int64?
            let title: String?
            let sourceUrls: String
            let resultMarkdown: String
            let createdAt: Date
        }

        return try await db.read { db in
            let rows = try CompareRow.fetchAll(
                db,
                sql: """
                SELECT id, workspace_id AS workspaceId, title, source_urls AS sourceUrls, result_markdown AS resultMarkdown, created_at AS createdAt
                FROM compare_sessions
                ORDER BY created_at DESC
                LIMIT ?
                """,
                arguments: [limit]
            )

            return rows.map { row in
                let urls = (try? JSONDecoder().decode([String].self, from: Data(row.sourceUrls.utf8))) ?? []
                return CompareSession(
                    id: row.id,
                    workspaceId: row.workspaceId,
                    title: row.title,
                    sourceUrls: urls,
                    resultMarkdown: row.resultMarkdown,
                    createdAt: row.createdAt
                )
            }
        }
    }

    func createWatchRule(url: String, title: String?, watchType: String, prompt: String?) async throws -> WatchRule {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.write { db in
            let createdAt = Date()
            let uuid = UUID().uuidString
            try db.execute(
                sql: """
                INSERT INTO watch_rules (uuid, url, title, watch_type, prompt, status, last_checked_at, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [uuid, url, title, watchType, prompt, WatchRule.Status.active.rawValue, nil as Date?, createdAt]
            )

            return WatchRule(
                id: db.lastInsertedRowID,
                uuid: uuid,
                url: url,
                title: title,
                watchType: watchType,
                prompt: prompt,
                status: .active,
                lastCheckedAt: nil,
                createdAt: createdAt
            )
        }
    }

    func getWatchRules() async throws -> [WatchRule] {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            try WatchRule
                .order(Column("created_at").desc)
                .fetchAll(db)
        }
    }

    func updateWatchRuleCheck(id: Int64, status: WatchRule.Status) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            try db.execute(
                sql: """
                UPDATE watch_rules
                SET status = ?, last_checked_at = ?
                WHERE id = ?
                """,
                arguments: [status.rawValue, Date(), id]
            )
        }
    }

    func deleteWatchRule(id: Int64) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            _ = try WatchRule.deleteOne(db, key: id)
        }
    }

    func addWatchSnapshot(_ snapshot: WatchSnapshot) async throws {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        try await db.write { db in
            let inserted = snapshot
            try inserted.insert(db)
        }
    }

    func getLatestWatchSnapshot(ruleId: Int64) async throws -> WatchSnapshot? {
        guard let db = dbQueue else { throw StorageError.databaseNotInitialized }

        return try await db.read { db in
            try WatchSnapshot
                .filter(Column("watch_rule_id") == ruleId)
                .order(Column("created_at").desc)
                .fetchOne(db)
        }
    }
}

struct SearchResults {
    let indexResults: [SearchIndexEntry]
    let historyResults: [HistoryEntry]
    let memoryResults: [PageMemory]
}

enum StorageError: Error {
    case databaseNotInitialized
    case queryFailed(Error)
}
