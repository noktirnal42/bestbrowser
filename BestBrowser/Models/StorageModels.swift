import Foundation
import GRDB

// MARK: - History Entry
struct HistoryEntry: Identifiable, Codable {
    var id: Int64?
    let url: String
    let title: String
    let timestamp: Date
    var visitCount: Int = 1
    var lastVisit: Date?

    enum CodingKeys: String, CodingKey {
        case id, url, title, timestamp, visitCount, lastVisit
    }
}

extension HistoryEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "history"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        self.id = inserted.rowID
    }
}

// MARK: - Bookmark
struct Bookmark: Identifiable, Codable {
    var id: Int64?
    let url: String
    let title: String
    let folder: String
    let createdAt: Date
    var modifiedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, url, title, folder, createdAt, modifiedAt
    }
}

extension Bookmark: FetchableRecord, PersistableRecord {
    static let databaseTableName = "bookmarks"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        self.id = inserted.rowID
    }
}

// MARK: - Storage Setting
struct StorageSetting: Identifiable, Codable {
    var id: String { key }
    let key: String
    let value: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case key, value, updatedAt
    }
}

extension StorageSetting: FetchableRecord, PersistableRecord {
    static let databaseTableName = "settings"
    static let databasePrimaryKey = "key"
}

// MARK: - Search Index Entry
struct SearchIndexEntry: Identifiable, Codable {
    var id: Int64?
    let sourceId: Int64
    let sourceType: String // "history", "bookmark", "page"
    let title: String
    let content: String
    let url: String
    let indexedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, sourceId, sourceType, title, content, url, indexedAt
    }
}

extension SearchIndexEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "search_index"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        self.id = inserted.rowID
    }
}
