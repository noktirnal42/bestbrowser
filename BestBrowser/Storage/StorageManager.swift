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
            let queue = try DatabaseQueue(path: dbURL.path)
            try await StorageSchema.prepare(in: queue)
            dbQueue = queue
            isInitialized = true
        } catch {
            print("❌ Database initialization failed: \(error)")
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
        try await write { db in
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
        try await read { db in
            try HistoryEntry
                .order(Column("timestamp").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func searchHistory(_ query: String) async throws -> [HistoryEntry] {
        try await read { db in
            try HistoryEntry
                .filter(Column("url").like("%\(query)%") || Column("title").like("%\(query)%"))
                .order(Column("timestamp").desc)
                .fetchAll(db)
        }
    }

    func clearHistory() async throws {
        try await write { db in
            try db.execute(sql: "DELETE FROM history")
            try db.execute(sql: "DELETE FROM search_index WHERE source_type = 'history'")
        }
    }

    func deleteHistoryEntry(id: Int64) async throws {
        try await write { db in
            _ = try HistoryEntry.deleteOne(db, key: id)
        }
    }

    func clearSearchIndex() async throws {
        try await write { db in
            try db.execute(sql: "DELETE FROM search_index")
        }
    }

    func addBookmark(url: String, title: String, folder: String = "Default") async throws {
        try await write { db in
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
        try await read { db in
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
        try await write { db in
            _ = try Bookmark.deleteOne(db, key: id)
        }
    }

    func setSetting(_ key: String, value: String) async throws {
        try await write { db in
            let setting = StorageSetting(key: key, value: value, updatedAt: Date())
            try setting.upsert(db)
        }
    }

    func getSetting(_ key: String) async throws -> String? {
        try await read { db in
            try StorageSetting.fetchOne(db, key: key)?.value
        }
    }

    func indexSearch(title: String, content: String, url: String, sourceId: Int64, sourceType: String) async throws {
        try await write { db in
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
        try await read { db in
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
        try await write { db in
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
        try await read { db in
            try Workspace
                .order(Column("updated_at").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func updateWorkspace(id: Int64, title: String, purpose: String?, summary: String?) async throws {
        try await write { db in
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
        try await write { db in
            _ = try Workspace.deleteOne(db, key: id)
        }
    }

    func getWorkspaceTabs(workspaceId: Int64) async throws -> [WorkspaceTab] {
        try await read { db in
            try WorkspaceTab
                .filter(Column("workspace_id") == workspaceId)
                .order(Column("added_at").asc)
                .fetchAll(db)
        }
    }

    func replaceWorkspaceTabs(workspaceId: Int64, tabs: [WorkspaceTab]) async throws {
        try await write { db in
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
        try await write { db in
            let openedAt = Date()
            try db.execute(
                sql: """
                UPDATE workspaces
                SET last_opened_at = ?, updated_at = ?
                WHERE id = ?
                """,
                arguments: [openedAt, openedAt, id]
            )
        }
    }

    func upsertPageMemory(_ memory: PageMemory) async throws {
        try await write { db in
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
        try await read { db in
            try PageMemory
                .order(Column("is_pinned").desc, Column("last_visited_at").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func updatePageMemory(id: Int64, note: String?, isPinned: Bool) async throws {
        try await write { db in
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
        let payload = try JSONEncoder().encode(sourceUrls)
        let payloadString = String(data: payload, encoding: .utf8) ?? "[]"

        try await write { db in
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
        struct CompareRow: FetchableRecord, Decodable {
            let id: Int64
            let workspaceId: Int64?
            let title: String?
            let sourceUrls: String
            let resultMarkdown: String
            let createdAt: Date
        }

        return try await read { db in
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
        try await write { db in
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
        try await read { db in
            try WatchRule
                .order(Column("created_at").desc)
                .fetchAll(db)
        }
    }

    func updateWatchRuleCheck(id: Int64, status: WatchRule.Status) async throws {
        try await write { db in
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
        try await write { db in
            _ = try WatchRule.deleteOne(db, key: id)
        }
    }

    func addWatchSnapshot(_ snapshot: WatchSnapshot) async throws {
        try await write { db in
            let inserted = snapshot
            try inserted.insert(db)
        }
    }

    func getLatestWatchSnapshot(ruleId: Int64) async throws -> WatchSnapshot? {
        try await read { db in
            try WatchSnapshot
                .filter(Column("watch_rule_id") == ruleId)
                .order(Column("created_at").desc)
                .fetchOne(db)
        }
    }

    private func databaseQueue() throws -> DatabaseQueue {
        guard let dbQueue else { throw StorageError.databaseNotInitialized }
        return dbQueue
    }

    private func read<T>(_ block: @escaping (Database) throws -> T) async throws -> T {
        try databaseQueue().read(block)
    }

    private func write<T>(_ block: @escaping (Database) throws -> T) async throws -> T {
        try databaseQueue().write(block)
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
