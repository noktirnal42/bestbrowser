import Foundation
import SwiftUI

@MainActor
final class BrowserShellStore: ObservableObject {
    static let shared = BrowserShellStore()

    @Published var showingSettings = false
    @Published var showSidebar = true
    @Published var showCommandPalette = false
    @Published var commandQuery = ""
    @Published var showingDownloads = false
    @Published var focusMode = false
    @Published var readingModePayload: ReadingModePayload?
    @Published var comparePresentation: ComparePresentation?
    @Published var splitPickerVisible = false
    @Published var splitPickerPrimaryTabId: UUID?
    @Published var editingGroup: TabGroup?

    init() {}

    func toggleSidebar() {
        showSidebar.toggle()
    }

    func presentCommandPalette(query: String = "") {
        commandQuery = query
        showCommandPalette = true
    }

    func dismissCommandPalette() {
        commandQuery = ""
        showCommandPalette = false
    }

    func presentSettings() {
        showingSettings = true
    }

    func presentDownloads() {
        showingDownloads = true
    }

    func toggleFocusMode() {
        focusMode.toggle()
    }

    func exitFocusMode() {
        focusMode = false
    }

    func presentSplitPicker(primaryTabId: UUID?) {
        splitPickerPrimaryTabId = primaryTabId
        splitPickerVisible = true
    }

    func dismissSplitPicker() {
        splitPickerPrimaryTabId = nil
        splitPickerVisible = false
    }

    func clearTransientPresentations() {
        showCommandPalette = false
        commandQuery = ""
        showingSettings = false
        showingDownloads = false
        focusMode = false
        readingModePayload = nil
        comparePresentation = nil
        splitPickerVisible = false
        splitPickerPrimaryTabId = nil
        editingGroup = nil
    }
}
