import Foundation
import GRDB

struct PageMemory: Identifiable, Codable {
    var id: Int64?
    var url: String
    var normalizedUrl: String
    var title: String?
    var host: String?
    var summary: String?
    var takeaway: String?
    var keywords: String?
    var note: String?
    var isPinned: Bool
    var lastVisitedAt: Date
    var visitCount: Int

    init(
        id: Int64? = nil,
        url: String,
        normalizedUrl: String,
        title: String? = nil,
        host: String? = nil,
        summary: String? = nil,
        takeaway: String? = nil,
        keywords: String? = nil,
        note: String? = nil,
        isPinned: Bool = false,
        lastVisitedAt: Date = Date(),
        visitCount: Int = 1
    ) {
        self.id = id
        self.url = url
        self.normalizedUrl = normalizedUrl
        self.title = title
        self.host = host
        self.summary = summary
        self.takeaway = takeaway
        self.keywords = keywords
        self.note = note
        self.isPinned = isPinned
        self.lastVisitedAt = lastVisitedAt
        self.visitCount = visitCount
    }

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case normalizedUrl = "normalized_url"
        case title
        case host
        case summary
        case takeaway
        case keywords
        case note
        case isPinned = "is_pinned"
        case lastVisitedAt = "last_visited_at"
        case visitCount = "visit_count"
    }
}

extension PageMemory: FetchableRecord, PersistableRecord {
    static let databaseTableName = "page_memory"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct CompareSession: Identifiable, Codable {
    var id: Int64?
    var workspaceId: Int64?
    var title: String?
    var sourceUrls: [String]
    var resultMarkdown: String
    var createdAt: Date

    init(
        id: Int64? = nil,
        workspaceId: Int64? = nil,
        title: String? = nil,
        sourceUrls: [String],
        resultMarkdown: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.workspaceId = workspaceId
        self.title = title
        self.sourceUrls = sourceUrls
        self.resultMarkdown = resultMarkdown
        self.createdAt = createdAt
    }
}

struct WatchRule: Identifiable, Codable {
    enum Status: String, Codable, CaseIterable, Identifiable {
        case active
        case paused

        var id: String { rawValue }
    }

    var id: Int64?
    var uuid: String
    var url: String
    var title: String?
    var watchType: String
    var prompt: String?
    var status: Status
    var lastCheckedAt: Date?
    var createdAt: Date

    init(
        id: Int64? = nil,
        uuid: String = UUID().uuidString,
        url: String,
        title: String? = nil,
        watchType: String = "page-change",
        prompt: String? = nil,
        status: Status = .active,
        lastCheckedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.uuid = uuid
        self.url = url
        self.title = title
        self.watchType = watchType
        self.prompt = prompt
        self.status = status
        self.lastCheckedAt = lastCheckedAt
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case url
        case title
        case watchType = "watch_type"
        case prompt
        case status
        case lastCheckedAt = "last_checked_at"
        case createdAt = "created_at"
    }
}

extension WatchRule: FetchableRecord, PersistableRecord {
    static let databaseTableName = "watch_rules"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct WatchSnapshot: Identifiable, Codable {
    var id: Int64?
    var watchRuleId: Int64
    var contentHash: String
    var summary: String?
    var changeSummary: String?
    var createdAt: Date

    init(
        id: Int64? = nil,
        watchRuleId: Int64,
        contentHash: String,
        summary: String? = nil,
        changeSummary: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.watchRuleId = watchRuleId
        self.contentHash = contentHash
        self.summary = summary
        self.changeSummary = changeSummary
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case watchRuleId = "watch_rule_id"
        case contentHash = "content_hash"
        case summary
        case changeSummary = "change_summary"
        case createdAt = "created_at"
    }
}

extension WatchSnapshot: FetchableRecord, PersistableRecord {
    static let databaseTableName = "watch_snapshots"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct WatchStatusSummary: Identifiable {
    let id: Int64
    let rule: WatchRule
    let latestSnapshot: WatchSnapshot?
}

struct ComparedTabContext: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let content: String
}

struct CompareCitation: Identifiable, Hashable {
    let id = UUID()
    let index: Int
    let title: String
    let url: String
    let host: String
}

struct ComparePresentation: Identifiable {
    let id = UUID()
    let markdown: String
    let citations: [CompareCitation]
}
