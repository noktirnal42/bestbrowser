import XCTest
@testable import BestBrowser

@MainActor
final class BrowserSessionCoordinatorTests: XCTestCase {
    func testMakeClosedTabRecordSkipsNewTabURL() {
        let coordinator = BrowserSessionCoordinator.shared
        let tab = BrowserTab(id: UUID(), url: BrowserViewModel.newTabURL, title: "New Tab", favicon: nil, groupId: nil)

        let record = coordinator.makeClosedTabRecord(from: tab, newTabURL: BrowserViewModel.newTabURL)

        XCTAssertNil(record)
    }

    func testPrependClosedTabRecordKeepsNewestFirst() {
        let coordinator = BrowserSessionCoordinator.shared
        let older = ClosedTabRecord(id: UUID(), url: "https://older.example", title: "Older", favicon: nil, closedAt: .distantPast)
        let newer = ClosedTabRecord(id: UUID(), url: "https://new.example", title: "New", favicon: nil, closedAt: .now)

        let result = coordinator.prependClosedTabRecord(newer, to: [older], limit: 5)

        XCTAssertEqual(result.map(\.url), ["https://new.example", "https://older.example"])
    }

    func testArchiveSessionIfNeededDeduplicatesLatestURLs() {
        let coordinator = BrowserSessionCoordinator.shared
        let navigationStore = BrowserNavigationStore()

        navigationStore.openNewTab(newTabURL: BrowserViewModel.newTabURL)
        navigationStore.updateURL("https://one.example", for: navigationStore.activeTabId)
        navigationStore.openNewTab(newTabURL: BrowserViewModel.newTabURL)
        navigationStore.updateURL("https://two.example", for: navigationStore.activeTabId)

        let existing = coordinator.archiveSessionIfNeeded(
            navigationStore: navigationStore,
            currentTabTitle: "Two",
            existing: [],
            newTabURL: BrowserViewModel.newTabURL
        )

        let deduped = coordinator.archiveSessionIfNeeded(
            navigationStore: navigationStore,
            currentTabTitle: "Two",
            existing: existing,
            newTabURL: BrowserViewModel.newTabURL
        )

        XCTAssertEqual(existing.count, 1)
        XCTAssertEqual(deduped.count, 1)
        XCTAssertEqual(deduped.first?.snapshot.tabs.map(\.url), ["https://one.example", "https://two.example"])
    }
}
