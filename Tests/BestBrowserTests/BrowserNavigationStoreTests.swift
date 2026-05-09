import XCTest
@testable import BestBrowser

@MainActor
final class BrowserNavigationStoreTests: XCTestCase {
    func testSelectTabNilClearsActiveSelection() {
        let store = BrowserNavigationStore()

        store.openNewTab(newTabURL: BrowserViewModel.newTabURL)
        let originalTabID = try? XCTUnwrap(store.activeTabId)

        store.selectTab(nil)

        XCTAssertNil(store.activeTabId)
        XCTAssertEqual(store.currentURL, "")
        XCTAssertNotNil(originalTabID)
    }

    func testCurrentURLTracksOnlySelectedTab() {
        let store = BrowserNavigationStore()

        store.openNewTab(newTabURL: BrowserViewModel.newTabURL)
        let firstTabID = try! XCTUnwrap(store.activeTabId)
        store.updateURL("https://example.com", for: firstTabID)

        store.openNewTab(newTabURL: BrowserViewModel.newTabURL)
        let secondTabID = try! XCTUnwrap(store.activeTabId)
        store.updateURL("https://openai.com", for: secondTabID)

        store.updateURL("https://example.com/updated", for: firstTabID)

        XCTAssertEqual(store.currentURL, "https://openai.com")
        XCTAssertEqual(store.tab(for: firstTabID)?.url, "https://example.com/updated")
        XCTAssertEqual(store.tab(for: secondTabID)?.url, "https://openai.com")
    }
}
