import Foundation
import Observation

@Observable
@MainActor
final class BrowserWorkspaceStore {
    enum SurfaceMode: String, Codable, CaseIterable {
        case browser
        case workspaces
        case watches
        case memory
        case extensions
        case music
        case video
    }

    var tabs: [BrowserTab] = []
    var selectedTabID: UUID?
    var surfaceMode: SurfaceMode = .browser
    var sidebarVisible = true
    var inspectorVisible = false

    func navigate(to mode: SurfaceMode) {
        surfaceMode = mode
    }

    func showBrowser() {
        surfaceMode = .browser
    }

    func toggleSidebar() {
        sidebarVisible.toggle()
    }

    func toggleInspector() {
        inspectorVisible.toggle()
    }

    func bootstrap(with tabs: [BrowserTab]) {
        self.tabs = tabs
        if selectedTabID == nil {
            selectedTabID = tabs.first?.id
        }
    }

    func selectTab(_ id: UUID?) {
        selectedTabID = id
    }

    func open(tab: BrowserTab) {
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func close(tabID: UUID) {
        tabs.removeAll { $0.id == tabID }
        if selectedTabID == tabID {
            selectedTabID = tabs.last?.id
        }
    }
}
