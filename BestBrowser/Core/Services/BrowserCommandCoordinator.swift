import Foundation

@MainActor
enum BrowserCommand: String {
    case newTab = "New Tab"
    case closeTab = "Close Tab"
    case reopenClosedTab = "Reopen Closed Tab"
    case toggleSplitView = "Split View"
    case toggleVerticalTabs = "Toggle Vertical Tabs"
    case groupCurrentTab = "Group Current Tab"
    case openSettings = "Settings"
    case toggleFocusMode = "Focus Mode"
    case briefSession = "Brief Session"
    case compareTabs = "Compare Tabs"
    case watchCurrentPage = "Watch Current Page"
    case summarize = "Summarize"
    case openReadingMode = "Reading Mode"
    case repairVideoLayout = "Repair Video Layout"
    case openDownloads = "Downloads"
    case showHistory = "History"
    case cleanPage = "Clean Page"
}

@MainActor
final class BrowserCommandCoordinator {
    static let shared = BrowserCommandCoordinator()

    private let browserModel: BrowserViewModel
    private let shellStore: BrowserShellStore
    private let aiClient: AIClient
    private let workspaceService: WorkspaceService
    private let compareService: CompareService
    private let watchService: WatchService

    init(
        browserModel: BrowserViewModel = .shared,
        shellStore: BrowserShellStore = .shared,
        aiClient: AIClient = .shared,
        workspaceService: WorkspaceService = .shared,
        compareService: CompareService = .shared,
        watchService: WatchService = .shared
    ) {
        self.browserModel = browserModel
        self.shellStore = shellStore
        self.aiClient = aiClient
        self.workspaceService = workspaceService
        self.compareService = compareService
        self.watchService = watchService
    }

    func execute(_ command: BrowserCommand) {
        switch command {
        case .newTab:
            browserModel.newTab()
        case .closeTab:
            browserModel.closeTab(id: browserModel.activeTabId ?? UUID())
        case .reopenClosedTab:
            browserModel.reopenClosedTab()
        case .toggleSplitView:
            if browserModel.isSplitViewActive {
                browserModel.toggleSplitView()
            } else {
                shellStore.presentSplitPicker(primaryTabId: browserModel.activeTabId)
            }
        case .toggleVerticalTabs:
            browserModel.toggleVerticalTabs()
        case .groupCurrentTab:
            browserModel.createGroupFromCurrentTab()
        case .openSettings:
            shellStore.presentSettings()
        case .toggleFocusMode:
            shellStore.toggleFocusMode()
        case .briefSession:
            shellStore.showSidebar = true
            Task { await workspaceService.refreshSessionInsights() }
        case .compareTabs:
            Task {
                let result = await compareService.compareOpenTabs()
                await MainActor.run {
                    self.shellStore.comparePresentation = result
                }
            }
        case .watchCurrentPage:
            shellStore.showSidebar = true
            Task { await watchService.addCurrentPageWatch() }
        case .summarize:
            guard aiClient.isAvailable else {
                shellStore.presentSettings()
                return
            }
            shellStore.showSidebar = true
        case .openReadingMode:
            Task { await presentReadingMode() }
        case .repairVideoLayout:
            browserModel.repairYouTubeLayout()
        case .openDownloads:
            shellStore.presentDownloads()
        case .showHistory:
            shellStore.showSidebar = true
        case .cleanPage:
            browserModel.handleCleanPage()
        }
    }

    private func presentReadingMode() async {
        guard let content = await browserModel.currentPageContent(),
              let currentTab = browserModel.currentTab,
              !browserModel.isNewTab(currentTab) else { return }

        shellStore.readingModePayload = ReadingModePayload(
            title: currentTab.title.isEmpty ? currentTab.url : currentTab.title,
            content: content,
            url: currentTab.url
        )
    }
}
