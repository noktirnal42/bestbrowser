import Foundation
import Combine
import WebKit
import AppKit

@MainActor
class BrowserViewModel: ObservableObject {
    static let newTabURL = "bestbrowser://new-tab"

    @Published var tabs: [BrowserTab] = []
    @Published var activeTabId: UUID?
    @Published var url: String = ""
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var currentMediaVolume: Double = 1
    @Published var currentMediaMuted: Bool = false
    @Published var currentTabHasMedia = false
    @Published var verticalTabsEnabled: Bool = false
    @Published var splitPrimaryTabId: UUID?
    @Published var splitTabId: UUID?
    @Published var tabGroups: [TabGroup] = []
    @Published private(set) var closedTabs: [ClosedTabRecord] = []
    @Published private(set) var closedSessions: [ClosedSessionRecord] = []
    @Published private(set) var youtubeFocusedLiveTabIds: Set<UUID> = []

    private var webViewInstances: [UUID: WKWebView] = [:]
    private let navigationStore = BrowserNavigationStore()

    let storage = StorageManager.shared
    let privacyShield = PrivacyShield.shared
    let pageMemoryService = PageMemoryService.shared
    let pageActionService = BrowserPageActionService.shared
    let pageContextService = BrowserPageContextService.shared
    let sessionCoordinator = BrowserSessionCoordinator.shared
    let sessionRestoreService = SessionRestoreService.shared
    let siteCompatibility = SiteCompatibilityService.shared
    let playbackControls = MediaPlaybackControlService.shared

    static var shared = BrowserViewModel()

    var currentWebView: WKWebView? {
        guard let tabId = activeTabId else { return nil }
        return webViewInstances[tabId]
    }

    init() {
        closedTabs = sessionCoordinator.initialClosedTabs(using: sessionRestoreService)
        closedSessions = sessionCoordinator.initialClosedSessions(using: sessionRestoreService)
        restoreSessionIfAvailable()

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleCleanPage), name: .cleanPageContent, object: nil)
        center.addObserver(self, selector: #selector(handleStripPopups), name: .stripPopupsNow, object: nil)
    }

    func registerWebView(_ webView: WKWebView, for tabId: UUID) {
        webViewInstances[tabId] = webView
        updateNavigationState(for: tabId)
        if tabId == activeTabId {
            refreshCurrentMediaState()
        }
    }

    func unregisterWebView(for tabId: UUID) {
        webViewInstances.removeValue(forKey: tabId)
    }

    private func updateNavigationState(for tabId: UUID) {
        guard let webView = webViewInstances[tabId],
              tabId == activeTabId else { return }

        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }

    func updateNavigationState() {
        guard let tabId = activeTabId else { return }
        updateNavigationState(for: tabId)
        refreshCurrentMediaState()
    }

    func newTab() {
        navigationStore.openNewTab(newTabURL: Self.newTabURL)
        commitNavigationChange(refreshActiveNavigation: true)
    }

    func closeTab(id: UUID) {
        guard let removedTab = tabs.first(where: { $0.id == id }) else { return }
        archiveCurrentSessionIfNeeded()
        youtubeFocusedLiveTabIds.remove(id)

        if let closedRecord = sessionCoordinator.makeClosedTabRecord(from: removedTab, newTabURL: Self.newTabURL) {
            closedTabs = sessionCoordinator.prependClosedTabRecord(closedRecord, to: closedTabs)
            sessionRestoreService.saveClosedTabs(closedTabs)
        }

        navigationStore.closeTab(id: id)
        syncNavigationState()
        webViewInstances.removeValue(forKey: id)

        DispatchQueue.main.async {
            self.updateNavigationState()
            NotificationCenter.default.post(name: .refreshWorkspaceSession, object: nil)
            self.persistSession()
        }
    }

    func loadUrl(_ urlString: String) {
        loadUrl(urlString, for: activeTabId)
    }

    func loadUrl(_ urlString: String, for tabId: UUID?) {
        let resolvedTarget = resolveNavigationTarget(for: urlString)

        if let tabId,
           tabs.contains(where: { $0.id == tabId }) {
            if !siteCompatibility.isYouTubeWatchURL(resolvedTarget) {
                youtubeFocusedLiveTabIds.remove(tabId)
            }
            navigationStore.updateURL(resolvedTarget, for: tabId)
            syncNavigationState()

            if let webView = webViewInstances[tabId] {
                if let newUrl = URL(string: resolvedTarget) {
                    webView.load(URLRequest(url: newUrl))
                }
            }
            persistSession()
        }
    }

    func openAuthenticationRequest(_ url: URL, additionalHeaders: [String: String]? = nil) {
        newTab()

        guard let tabId = activeTabId else { return }

        navigationStore.updateURL(url.absoluteString, for: tabId)
        syncNavigationState()

        if let webView = webViewInstances[tabId] {
            var request = URLRequest(url: url)
            if let additionalHeaders, !additionalHeaders.isEmpty {
                for (key, value) in additionalHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            webView.load(request)
        }

        persistSession()
    }

    func completeAuthenticationIfNeeded(with url: URL, isMainFrame: Bool) -> Bool {
        BrowserAuthenticationService.shared.completeAuthenticationIfNeeded(with: url, isMainFrame: isMainFrame)
    }

    func openInCurrentTab(_ target: String) {
        loadUrl(target)
    }

    func reopenClosedTab() {
        guard let record = closedTabs.first else { return }
        reopenClosedTab(record)
    }

    func reopenClosedTab(_ record: ClosedTabRecord) {
        guard closedTabs.contains(where: { $0.id == record.id }) else { return }

        closedTabs = sessionCoordinator.removingClosedTabRecord(matching: record, from: closedTabs)
        sessionRestoreService.saveClosedTabs(closedTabs)

        navigationStore.reopenTab(from: record)
        commitNavigationChange(refreshActiveNavigation: true, refreshWorkspaceSession: false)
    }

    func restoreClosedSession(_ record: ClosedSessionRecord) {
        guard closedSessions.contains(where: { $0.id == record.id }) else { return }
        closedSessions = sessionCoordinator.removingClosedSessionRecord(matching: record, from: closedSessions)
        sessionRestoreService.saveClosedSessions(closedSessions)
        restore(from: record.snapshot)
    }

    var currentTab: BrowserTab? {
        navigationStore.currentTab
    }

    func selectTab(_ tabId: UUID?) {
        navigationStore.selectTab(tabId)
        syncNavigationState()
        if let tabId {
            updateNavigationState(for: tabId)
        }
        refreshCurrentMediaState()
    }

    func isNewTab(_ tab: BrowserTab) -> Bool {
        tab.url == Self.newTabURL
    }

    func addCurrentPageToBookmarks() async throws {
        guard let tabId = activeTabId,
              let tab = tabs.first(where: { $0.id == tabId }),
              !tab.url.isEmpty else { return }

        let title = tab.title.isEmpty ? tab.url : tab.title
        try await storage.addBookmark(url: tab.url, title: title)
    }

    func currentPageContent() async -> String? {
        guard let webView = currentWebView else { return nil }
        return await pageContextService.textContent(from: webView)
    }

    func evaluateCurrentPageJavaScript(_ script: String) {
        currentWebView?.evaluateJavaScript(script, completionHandler: nil)
    }

    func content(for tabId: UUID) async -> String? {
        guard let webView = webViewInstances[tabId] else { return nil }
        return await pageContextService.textContent(from: webView)
    }

    func openTabContexts(limit: Int = 4) async -> [ComparedTabContext] {
        await pageContextService.comparedContexts(
            from: tabs,
            webViews: webViewInstances,
            newTabURL: Self.newTabURL,
            limit: limit
        )
    }

    func goBack() {
        goBack(for: activeTabId)
    }

    func goBack(for tabId: UUID?) {
        guard let tabId,
              let webView = webViewInstances[tabId],
              webView.canGoBack else { return }
        webView.goBack()
    }

    func goForward() {
        goForward(for: activeTabId)
    }

    func goForward(for tabId: UUID?) {
        guard let tabId,
              let webView = webViewInstances[tabId],
              webView.canGoForward else { return }
        webView.goForward()
    }

    func refresh() {
        refresh(for: activeTabId)
    }

    func refresh(for tabId: UUID?) {
        guard let tabId, let webView = webViewInstances[tabId] else { return }
        webView.reload()
    }

    func setCurrentTabVolume(_ volume: Double) {
        guard let webView = currentWebView else { return }
        currentMediaVolume = min(max(volume, 0), 1)
        playbackControls.applyState(volume: currentMediaVolume, muted: currentMediaMuted, to: webView)
    }

    func toggleCurrentTabMuted() {
        guard let webView = currentWebView else { return }
        currentMediaMuted.toggle()
        playbackControls.applyState(volume: currentMediaVolume, muted: currentMediaMuted, to: webView)
    }

    func refreshCurrentMediaState() {
        guard let webView = currentWebView else {
            currentTabHasMedia = false
            currentMediaVolume = 1
            currentMediaMuted = false
            return
        }

        playbackControls.refreshState(from: webView) { [weak self] volume, muted, hasMedia in
            guard let self else { return }
            self.currentMediaVolume = volume
            self.currentMediaMuted = muted
            self.currentTabHasMedia = hasMedia
        }
    }

    func isYouTubeFocusedLiveMode(for tabId: UUID) -> Bool {
        youtubeFocusedLiveTabIds.contains(tabId)
    }

    func enableYouTubeFocusedLiveMode(for tabId: UUID) {
        guard let tab = tabs.first(where: { $0.id == tabId }),
              siteCompatibility.youTubeEmbedURL(for: tab) != nil else { return }
        youtubeFocusedLiveTabIds.insert(tabId)
    }

    func disableYouTubeFocusedLiveMode(for tabId: UUID) {
        youtubeFocusedLiveTabIds.remove(tabId)
    }

    func youTubeEmbedURL(for tab: BrowserTab) -> String? {
        siteCompatibility.youTubeEmbedURL(for: tab)
    }

    func updateUrl(_ newUrl: String, for tabId: UUID? = nil) {
        let resolvedTabId = tabId ?? activeTabId
        if let resolvedTabId,
           tabs.contains(where: { $0.id == resolvedTabId }) {
            if !siteCompatibility.isYouTubeWatchURL(newUrl) {
                youtubeFocusedLiveTabIds.remove(resolvedTabId)
            }
            navigationStore.updateURL(newUrl, for: resolvedTabId)
            syncNavigationState()

            let historyTitle = navigationStore.tab(for: resolvedTabId)?.title ?? newUrl

            Task {
                try? await storage.addHistory(newUrl, title: historyTitle)
            }
            persistSessionAndRefreshWorkspace()
        }
    }

    func updateTitle(_ title: String, for tabId: UUID? = nil) {
        let resolvedTabId = tabId ?? activeTabId
        if let resolvedTabId,
           tabs.contains(where: { $0.id == resolvedTabId }) {
            navigationStore.updateTitle(title, for: resolvedTabId)
            persistSessionAndRefreshWorkspace(syncState: true)
        }
    }

    func updateFavicon(_ favicon: String?, for tabId: UUID) {
        guard tabs.contains(where: { $0.id == tabId }) else { return }
        navigationStore.updateFavicon(favicon, for: tabId)
        persistSessionAndRefreshWorkspace(syncState: true)
    }

    func sessionSnapshots() -> [SessionTabSnapshot] {
        navigationStore.sessionSnapshots(newTabURL: Self.newTabURL)
    }

    func loadWorkspaceTabs(_ workspaceTabs: [WorkspaceTabSnapshot]) {
        webViewInstances = [:]
        navigationStore.loadWorkspaceTabs(workspaceTabs, newTabURL: Self.newTabURL)
        syncNavigationState()
        canGoBack = false
        canGoForward = false
        persistSessionAndRefreshWorkspace()
    }

    func toggleSplitView() {
        navigationStore.toggleSplitView(newTabURL: Self.newTabURL)
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func setSplitTab(_ tabId: UUID?) {
        navigationStore.setSplitTab(tabId)
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func availableSplitCandidates() -> [BrowserTab] {
        navigationStore.availableSplitCandidates(newTabURL: Self.newTabURL)
    }

    func toggleVerticalTabs() {
        navigationStore.toggleVerticalTabs()
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func createGroupFromCurrentTab() {
        navigationStore.createGroupFromCurrentTab()
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func assignTab(_ tabId: UUID, to groupId: UUID?) {
        navigationStore.assignTab(tabId, to: groupId)
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func updateGroup(_ groupId: UUID, name: String, colorKey: String) {
        navigationStore.updateGroup(groupId, name: name, colorKey: colorKey)
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func moveTab(_ draggedTabId: UUID, toGroup targetGroupId: UUID?, before targetTabId: UUID? = nil) {
        navigationStore.moveTab(draggedTabId, toGroup: targetGroupId, before: targetTabId)
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func reorderGroup(_ draggedGroupId: UUID, before targetGroupId: UUID) {
        navigationStore.reorderGroup(draggedGroupId, before: targetGroupId)
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func removeGroup(_ groupId: UUID) {
        navigationStore.removeGroup(groupId)
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func toggleGroupCollapsed(_ groupId: UUID) {
        navigationStore.toggleGroupCollapsed(groupId)
        commitNavigationChange(refreshWorkspaceSession: false)
    }

    func group(for tabId: UUID) -> TabGroup? {
        navigationStore.group(for: tabId)
    }

    func tabs(in groupId: UUID) -> [BrowserTab] {
        navigationStore.tabs(in: groupId)
    }

    var ungroupedTabs: [BrowserTab] {
        navigationStore.ungroupedTabs
    }

    var isSplitViewActive: Bool {
        navigationStore.isSplitViewActive
    }

    var splitPrimaryTab: BrowserTab? {
        navigationStore.splitPrimaryTab
    }

    var splitSecondaryTab: BrowserTab? {
        navigationStore.splitSecondaryTab
    }

    func detectFavicon(for tabId: UUID, pageURL: URL?, webView: WKWebView) {
        Task {
            guard let faviconURL = await pageContextService.detectFaviconURL(pageURL: pageURL, in: webView),
                  !faviconURL.isEmpty else { return }
            await MainActor.run {
                self.updateFavicon(faviconURL, for: tabId)
            }
        }
    }

    @objc func handleCleanPage() {
        guard let webView = currentWebView else { return }
        pageActionService.cleanPage(in: webView, privacyShield: privacyShield, blocker: ElementBlocker.shared)
    }

    @objc func handleStripPopups() {
        guard let webView = currentWebView else { return }
        pageActionService.stripPopups(in: webView, privacyShield: privacyShield)
    }

    private func restoreSessionIfAvailable() {
        guard let snapshot = sessionCoordinator.initialSessionSnapshot(using: sessionRestoreService),
              !snapshot.tabs.isEmpty else {
            newTab()
            return
        }

        restore(from: snapshot)
    }

    private func restore(from snapshot: BrowserSessionSnapshot) {
        webViewInstances = [:]
        navigationStore.restore(from: snapshot, newTabURL: Self.newTabURL)
        syncNavigationState()
    }

    private func commitNavigationChange(
        refreshActiveNavigation: Bool = false,
        refreshWorkspaceSession: Bool = true
    ) {
        persistSessionAndRefreshWorkspace(syncState: true, refreshWorkspaceSession: refreshWorkspaceSession)

        if refreshActiveNavigation, let activeTabId {
            updateNavigationState(for: activeTabId)
        }
    }

    private func persistSessionAndRefreshWorkspace(
        syncState: Bool = false,
        refreshWorkspaceSession: Bool = true
    ) {
        if syncState {
            syncNavigationState()
        }

        if refreshWorkspaceSession {
            NotificationCenter.default.post(name: .refreshWorkspaceSession, object: nil)
        }

        persistSession()
    }

    private func persistSession() {
        sessionCoordinator.persistSession(
            navigationStore: navigationStore,
            using: sessionRestoreService,
            newTabURL: Self.newTabURL
        )
    }

    private func archiveCurrentSessionIfNeeded() {
        closedSessions = sessionCoordinator.archiveSessionIfNeeded(
            navigationStore: navigationStore,
            currentTabTitle: currentTab?.title,
            existing: closedSessions,
            newTabURL: Self.newTabURL
        )
        sessionRestoreService.saveClosedSessions(closedSessions)
    }

    private func resolveNavigationTarget(for input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return url }

        if let explicitURL = normalizedURL(from: trimmed) {
            return explicitURL.absoluteString
        }

        return searchURL(for: trimmed).absoluteString
    }

    private func normalizedURL(from input: String) -> URL? {
        if let directURL = URL(string: input),
           let scheme = directURL.scheme,
           ["http", "https"].contains(scheme.lowercased()),
           directURL.host != nil {
            return directURL
        }

        let looksLikeHost = input.contains(".") && !input.contains(" ")
        if looksLikeHost {
            return URL(string: "https://\(input)")
        }

        return nil
    }

    private func searchURL(for query: String) -> URL {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let defaults = UserDefaults.standard
        let engine = defaults.string(forKey: "searchEngine") ?? "duckduckgo"

        let template: String
        switch engine {
        case "brave":
            template = "https://search.brave.com/search?q=%@"
        case "google":
            template = "https://www.google.com/search?q=%@"
        case "bing":
            template = "https://www.bing.com/search?q=%@"
        case "custom":
            let customTemplate = defaults.string(forKey: "customSearchUrl") ?? ""
            if customTemplate.contains("%@") {
                template = customTemplate
            } else if !customTemplate.isEmpty {
                template = customTemplate + (customTemplate.contains("?") ? "&q=%@" : "?q=%@")
            } else {
                template = "https://duckduckgo.com/?q=%@"
            }
        default:
            template = "https://duckduckgo.com/?q=%@"
        }

        let target = String(format: template, encodedQuery)
        return URL(string: target) ?? URL(string: "https://duckduckgo.com/?q=\(encodedQuery)")!
    }

    func repairYouTubeLayout() {
        guard let activeTabId else { return }
        pageActionService.repairYouTubeLayout(for: activeTabId, using: self)
    }

    func repairYouTubeLayoutIfNeeded(for tabId: UUID) {
        guard let webView = webViewInstances[tabId] else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            let shouldFallback = await pageContextService.shouldUseYouTubeFocusedLiveFallback(
                in: webView,
                siteCompatibility: siteCompatibility
            )
            guard shouldFallback else { return }
            await MainActor.run {
                self.enableYouTubeFocusedLiveMode(for: tabId)
            }
        }
    }

    private func syncNavigationState() {
        tabs = navigationStore.tabs
        activeTabId = navigationStore.activeTabId
        url = navigationStore.currentURL
        verticalTabsEnabled = navigationStore.verticalTabsEnabled
        splitPrimaryTabId = navigationStore.splitPrimaryTabId
        splitTabId = navigationStore.splitTabId
        tabGroups = navigationStore.tabGroups
    }
}
