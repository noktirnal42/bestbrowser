import Foundation

@MainActor
final class BrowserSessionCoordinator {
    static let shared = BrowserSessionCoordinator()

    private init() {}

    func initialClosedTabs(using restoreService: SessionRestoreService) -> [ClosedTabRecord] {
        restoreService.restoreClosedTabs()
    }

    func initialClosedSessions(using restoreService: SessionRestoreService) -> [ClosedSessionRecord] {
        restoreService.restoreClosedSessions()
    }

    func initialSessionSnapshot(using restoreService: SessionRestoreService) -> BrowserSessionSnapshot? {
        restoreService.restoreSession()
    }

    func makeClosedTabRecord(from tab: BrowserTab, newTabURL: String) -> ClosedTabRecord? {
        guard tab.url != newTabURL else { return nil }
        return ClosedTabRecord(
            id: tab.id,
            url: tab.url,
            title: tab.title,
            favicon: tab.favicon,
            closedAt: Date()
        )
    }

    func prependClosedTabRecord(
        _ record: ClosedTabRecord,
        to existing: [ClosedTabRecord],
        limit: Int = 20
    ) -> [ClosedTabRecord] {
        Array(([record] + existing).prefix(limit))
    }

    func removingClosedTabRecord(
        matching record: ClosedTabRecord,
        from existing: [ClosedTabRecord]
    ) -> [ClosedTabRecord] {
        existing.filter { $0.id != record.id }
    }

    func removingClosedSessionRecord(
        matching record: ClosedSessionRecord,
        from existing: [ClosedSessionRecord]
    ) -> [ClosedSessionRecord] {
        existing.filter { $0.id != record.id }
    }

    func archiveSessionIfNeeded(
        navigationStore: BrowserNavigationStore,
        currentTabTitle: String?,
        existing: [ClosedSessionRecord],
        newTabURL: String,
        limit: Int = 12
    ) -> [ClosedSessionRecord] {
        let snapshotTabs = navigationStore.sessionSnapshots(newTabURL: newTabURL)
        guard snapshotTabs.count >= 2 else { return existing }

        let snapshot = navigationStore.makeSessionSnapshot(newTabURL: newTabURL)
        if let existingFirst = existing.first,
           existingFirst.snapshot.tabs.map(\.url) == snapshot.tabs.map(\.url) {
            return existing
        }

        let record = ClosedSessionRecord(
            id: UUID(),
            snapshot: snapshot,
            closedAt: Date(),
            title: currentTabTitle?.isEmpty == false ? currentTabTitle! : "Session Group"
        )

        return Array(([record] + existing).prefix(limit))
    }

    func persistSession(
        navigationStore: BrowserNavigationStore,
        using restoreService: SessionRestoreService,
        newTabURL: String
    ) {
        restoreService.saveSession(
            tabs: navigationStore.sessionSnapshots(newTabURL: newTabURL),
            activeTabId: navigationStore.activeTabId,
            splitPrimaryTabId: navigationStore.splitPrimaryTabId,
            splitTabId: navigationStore.splitTabId,
            tabGroups: navigationStore.tabGroups,
            verticalTabsEnabled: navigationStore.verticalTabsEnabled
        )
    }
}
