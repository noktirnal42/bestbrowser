import Foundation
import GRDB

enum WorkspaceStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case archived

    var id: String { rawValue }
}

struct Workspace: Identifiable, Codable {
    var id: Int64?
    let uuid: String
    var title: String
    var purpose: String?
    var summary: String?
    var status: WorkspaceStatus
    let createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?

    init(
        id: Int64? = nil,
        uuid: String = UUID().uuidString,
        title: String,
        purpose: String? = nil,
        summary: String? = nil,
        status: WorkspaceStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.title = title
        self.purpose = purpose
        self.summary = summary
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case title
        case purpose
        case summary
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastOpenedAt = "last_opened_at"
    }
}

extension Workspace: FetchableRecord, PersistableRecord {
    static let databaseTableName = "workspaces"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct WorkspaceTab: Identifiable, Codable {
    var id: Int64?
    var workspaceId: Int64
    var url: String
    var title: String?
    var faviconUrl: String?
    var note: String?
    var groupName: String?
    var groupColorKey: String?
    let addedAt: Date
    var lastSeenAt: Date?

    init(
        id: Int64? = nil,
        workspaceId: Int64,
        url: String,
        title: String? = nil,
        faviconUrl: String? = nil,
        note: String? = nil,
        groupName: String? = nil,
        groupColorKey: String? = nil,
        addedAt: Date = Date(),
        lastSeenAt: Date? = Date()
    ) {
        self.id = id
        self.workspaceId = workspaceId
        self.url = url
        self.title = title
        self.faviconUrl = faviconUrl
        self.note = note
        self.groupName = groupName
        self.groupColorKey = groupColorKey
        self.addedAt = addedAt
        self.lastSeenAt = lastSeenAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case url
        case title
        case faviconUrl = "favicon_url"
        case note
        case groupName = "group_name"
        case groupColorKey = "group_color_key"
        case addedAt = "added_at"
        case lastSeenAt = "last_seen_at"
    }
}

extension WorkspaceTab: FetchableRecord, PersistableRecord {
    static let databaseTableName = "workspace_tabs"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct WorkspaceTabSnapshot: Identifiable, Codable, Equatable {
    let id: UUID
    var url: String
    var title: String
    var faviconUrl: String?
    var note: String?
    var groupName: String?
    var groupColorKey: String?

    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        faviconUrl: String? = nil,
        note: String? = nil,
        groupName: String? = nil,
        groupColorKey: String? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.faviconUrl = faviconUrl
        self.note = note
        self.groupName = groupName
        self.groupColorKey = groupColorKey
    }
}
