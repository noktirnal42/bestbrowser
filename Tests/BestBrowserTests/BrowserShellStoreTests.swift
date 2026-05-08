import XCTest
@testable import BestBrowser

@MainActor
final class BrowserShellStoreTests: XCTestCase {
    func testCommandPalettePresentationLifecycle() {
        let store = BrowserShellStore()

        store.presentCommandPalette(query: "compare")

        XCTAssertTrue(store.showCommandPalette)
        XCTAssertEqual(store.commandQuery, "compare")

        store.dismissCommandPalette()

        XCTAssertFalse(store.showCommandPalette)
        XCTAssertEqual(store.commandQuery, "")
    }

    func testSplitPickerLifecycleTracksPrimaryTab() {
        let store = BrowserShellStore()
        let tabID = UUID()

        store.presentSplitPicker(primaryTabId: tabID)

        XCTAssertTrue(store.splitPickerVisible)
        XCTAssertEqual(store.splitPickerPrimaryTabId, tabID)

        store.dismissSplitPicker()

        XCTAssertFalse(store.splitPickerVisible)
        XCTAssertNil(store.splitPickerPrimaryTabId)
    }

    func testClearTransientPresentationsResetsShellState() {
        let store = BrowserShellStore()

        store.presentCommandPalette(query: "history")
        store.presentSettings()
        store.presentDownloads()
        store.toggleFocusMode()
        store.presentSplitPicker(primaryTabId: UUID())
        store.editingGroup = TabGroup(name: "Research")

        store.clearTransientPresentations()

        XCTAssertFalse(store.showCommandPalette)
        XCTAssertEqual(store.commandQuery, "")
        XCTAssertFalse(store.showingSettings)
        XCTAssertFalse(store.showingDownloads)
        XCTAssertFalse(store.focusMode)
        XCTAssertFalse(store.splitPickerVisible)
        XCTAssertNil(store.splitPickerPrimaryTabId)
        XCTAssertNil(store.editingGroup)
    }

    func testFocusModeLifecycle() {
        let store = BrowserShellStore()

        store.toggleFocusMode()
        XCTAssertTrue(store.focusMode)

        store.exitFocusMode()
        XCTAssertFalse(store.focusMode)
    }
}
