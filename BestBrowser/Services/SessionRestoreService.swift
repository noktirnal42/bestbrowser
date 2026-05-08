import Foundation

struct ClosedTabRecord: Codable, Identifiable {
    let id: UUID
    let url: String
    let title: String
    let favicon: String?
    let closedAt: Date
}

struct SessionTabSnapshot: Codable, Identifiable, Equatable {
    let id: UUID
    var url: String
    var title: String
    var faviconUrl: String?
    var groupId: UUID?
}

struct BrowserSessionSnapshot: Codable {
    let tabs: [SessionTabSnapshot]
    let activeTabId: UUID?
    let splitPrimaryTabId: UUID?
    let splitTabId: UUID?
    let tabGroups: [TabGroup]
    let verticalTabsEnabled: Bool
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case tabs
        case activeTabId
        case splitPrimaryTabId
        case splitTabId
        case tabGroups
        case verticalTabsEnabled
        case savedAt
        case activeTabURL
        case splitTabURL
    }

    init(
        tabs: [SessionTabSnapshot],
        activeTabId: UUID?,
        splitPrimaryTabId: UUID?,
        splitTabId: UUID?,
        tabGroups: [TabGroup],
        verticalTabsEnabled: Bool,
        savedAt: Date
    ) {
        self.tabs = tabs
        self.activeTabId = activeTabId
        self.splitPrimaryTabId = splitPrimaryTabId
        self.splitTabId = splitTabId
        self.tabGroups = tabGroups
        self.verticalTabsEnabled = verticalTabsEnabled
        self.savedAt = savedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTabs = try container.decode([SessionTabSnapshot].self, forKey: .tabs)
        let legacyActiveURL = try container.decodeIfPresent(String.self, forKey: .activeTabURL)
        let legacySplitURL = try container.decodeIfPresent(String.self, forKey: .splitTabURL)

        let decodedActiveTabId = try container.decodeIfPresent(UUID.self, forKey: .activeTabId)
            ?? legacyActiveURL.flatMap { activeURL in
                decodedTabs.first(where: { $0.url == activeURL })?.id
            }

        let decodedSplitPrimaryTabId = try container.decodeIfPresent(UUID.self, forKey: .splitPrimaryTabId)
            ?? legacyActiveURL.flatMap { activeURL in
                decodedTabs.first(where: { $0.url == activeURL })?.id
            }

        let decodedSplitTabId = try container.decodeIfPresent(UUID.self, forKey: .splitTabId)
            ?? legacySplitURL.flatMap { splitURL in
                decodedTabs.first(where: { $0.url == splitURL })?.id
            }

        tabs = decodedTabs
        activeTabId = decodedActiveTabId
        splitPrimaryTabId = decodedSplitPrimaryTabId
        splitTabId = decodedSplitTabId
        tabGroups = try container.decodeIfPresent([TabGroup].self, forKey: .tabGroups) ?? []
        verticalTabsEnabled = try container.decodeIfPresent(Bool.self, forKey: .verticalTabsEnabled) ?? false
        savedAt = try container.decodeIfPresent(Date.self, forKey: .savedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tabs, forKey: .tabs)
        try container.encodeIfPresent(activeTabId, forKey: .activeTabId)
        try container.encodeIfPresent(splitPrimaryTabId, forKey: .splitPrimaryTabId)
        try container.encodeIfPresent(splitTabId, forKey: .splitTabId)
        try container.encode(tabGroups, forKey: .tabGroups)
        try container.encode(verticalTabsEnabled, forKey: .verticalTabsEnabled)
        try container.encode(savedAt, forKey: .savedAt)
    }
}

struct ClosedSessionRecord: Codable, Identifiable {
    let id: UUID
    let snapshot: BrowserSessionSnapshot
    let closedAt: Date
    let title: String
}

@MainActor
final class SessionRestoreService: ObservableObject {
    static let shared = SessionRestoreService()

    private let sessionKey = "bestbrowser.session.snapshot"
    private let closedTabsKey = "bestbrowser.closed.tabs"
    private let closedSessionsKey = "bestbrowser.closed.sessions"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func saveSession(
        tabs: [SessionTabSnapshot],
        activeTabId: UUID?,
        splitPrimaryTabId: UUID?,
        splitTabId: UUID?,
        tabGroups: [TabGroup],
        verticalTabsEnabled: Bool
    ) {
        let snapshot = BrowserSessionSnapshot(
            tabs: tabs,
            activeTabId: activeTabId,
            splitPrimaryTabId: splitPrimaryTabId,
            splitTabId: splitTabId,
            tabGroups: tabGroups,
            verticalTabsEnabled: verticalTabsEnabled,
            savedAt: Date()
        )

        guard let data = try? encoder.encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: sessionKey)
    }

    func restoreSession() -> BrowserSessionSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else { return nil }
        return try? decoder.decode(BrowserSessionSnapshot.self, from: data)
    }

    func saveClosedTabs(_ tabs: [ClosedTabRecord]) {
        guard let data = try? encoder.encode(tabs) else { return }
        UserDefaults.standard.set(data, forKey: closedTabsKey)
    }

    func restoreClosedTabs() -> [ClosedTabRecord] {
        guard let data = UserDefaults.standard.data(forKey: closedTabsKey),
              let tabs = try? decoder.decode([ClosedTabRecord].self, from: data) else {
            return []
        }
        return tabs
    }

    func saveClosedSessions(_ sessions: [ClosedSessionRecord]) {
        guard let data = try? encoder.encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: closedSessionsKey)
    }

    func restoreClosedSessions() -> [ClosedSessionRecord] {
        guard let data = UserDefaults.standard.data(forKey: closedSessionsKey),
              let sessions = try? decoder.decode([ClosedSessionRecord].self, from: data) else {
            return []
        }
        return sessions
    }
}
