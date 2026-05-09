import XCTest
@testable import BestBrowser

@MainActor
final class BrowserWorkspaceStoreTests: XCTestCase {
    func testBootstrapSelectsFirstTabWhenUnset() {
        let store = BrowserWorkspaceStore()
        let first = BrowserTab(id: UUID(), url: "https://example.com", title: "Example", favicon: nil, groupId: nil)
        let second = BrowserTab(id: UUID(), url: "https://openai.com", title: "OpenAI", favicon: nil, groupId: nil)

        store.bootstrap(with: [first, second])

        XCTAssertEqual(store.tabs.count, 2)
        XCTAssertEqual(store.selectedTabID, first.id)
    }

    func testOpenCloseAndSelectionFlow() {
        let store = BrowserWorkspaceStore()
        let first = BrowserTab(id: UUID(), url: "https://example.com", title: "Example", favicon: nil, groupId: nil)
        let second = BrowserTab(id: UUID(), url: "https://openai.com", title: "OpenAI", favicon: nil, groupId: nil)

        store.open(tab: first)
        store.open(tab: second)

        XCTAssertEqual(store.selectedTabID, second.id)
        XCTAssertEqual(store.tabs.count, 2)

        store.close(tabID: second.id)

        XCTAssertEqual(store.tabs.count, 1)
        XCTAssertEqual(store.selectedTabID, first.id)
    }

    func testSceneRoutingAndVisibilityToggles() {
        let store = BrowserWorkspaceStore()

        store.navigate(to: .workspaces)
        XCTAssertEqual(store.surfaceMode, .workspaces)

        store.toggleSidebar()
        XCTAssertFalse(store.sidebarVisible)

        store.toggleInspector()
        XCTAssertTrue(store.inspectorVisible)

        store.showBrowser()
        XCTAssertEqual(store.surfaceMode, .browser)
    }

    func testSelectTabAllowsClearingAndIgnoresUnknownIDs() {
        let store = BrowserWorkspaceStore()
        let first = BrowserTab(id: UUID(), url: "https://example.com", title: "Example", favicon: nil, groupId: nil)
        let second = BrowserTab(id: UUID(), url: "https://openai.com", title: "OpenAI", favicon: nil, groupId: nil)

        store.bootstrap(with: [first, second])
        store.selectTab(second.id)
        XCTAssertEqual(store.selectedTabID, second.id)

        store.selectTab(UUID())
        XCTAssertEqual(store.selectedTabID, second.id)

        store.selectTab(nil)
        XCTAssertNil(store.selectedTabID)
    }
}
