import Foundation

@MainActor
final class BrowserNavigationStore {
    private(set) var tabs: [BrowserTab] = []
    private(set) var activeTabId: UUID?
    private(set) var currentURL: String = ""
    private(set) var verticalTabsEnabled = false
    private(set) var splitPrimaryTabId: UUID?
    private(set) var splitTabId: UUID?
    private(set) var tabGroups: [TabGroup] = []

    func openNewTab(newTabURL: String) {
        let tab = BrowserTab(id: UUID(), url: newTabURL, title: "New Tab")
        tabs.append(tab)
        activeTabId = tab.id
        currentURL = tab.url
    }

    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)

        if splitTabId == id {
            splitTabId = nil
        }
        if splitPrimaryTabId == id {
            splitPrimaryTabId = tabs.first?.id
        }

        if activeTabId == id {
            activeTabId = tabs.last?.id
            currentURL = currentTab?.url ?? ""
        }

        pruneEmptyGroups()
    }

    func reopenTab(from record: ClosedTabRecord) {
        let restoredTab = BrowserTab(
            id: UUID(),
            url: record.url,
            title: record.title.isEmpty ? record.url : record.title,
            favicon: record.favicon
        )
        tabs.append(restoredTab)
        activeTabId = restoredTab.id
        currentURL = restoredTab.url
    }

    func selectTab(_ tabId: UUID?) {
        guard let tabId,
              let tab = tabs.first(where: { $0.id == tabId }) else { return }
        activeTabId = tabId
        currentURL = tab.url
    }

    func updateURL(_ newURL: String, for tabId: UUID?) {
        guard let tabId,
              let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        tabs[index].url = newURL
        if activeTabId == tabId {
            currentURL = newURL
        }
    }

    func updateTitle(_ title: String, for tabId: UUID?) {
        guard let tabId,
              let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        tabs[index].title = title
    }

    func updateFavicon(_ favicon: String?, for tabId: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        tabs[index].favicon = favicon
    }

    func sessionSnapshots(newTabURL: String) -> [SessionTabSnapshot] {
        tabs
            .filter { !$0.url.isEmpty && $0.url != newTabURL }
            .map {
                SessionTabSnapshot(
                    id: $0.id,
                    url: $0.url,
                    title: $0.title.isEmpty ? $0.url : $0.title,
                    faviconUrl: $0.favicon,
                    groupId: $0.groupId
                )
            }
    }

    func loadWorkspaceTabs(_ workspaceTabs: [WorkspaceTabSnapshot], newTabURL: String) {
        let validTabs = workspaceTabs.filter { !$0.url.isEmpty }

        if validTabs.isEmpty {
            resetForEmptyState(newTabURL: newTabURL)
            return
        }

        var restoredGroups: [TabGroup] = []
        var groupIdsByDescriptor: [String: UUID] = [:]

        tabs = validTabs.map { snapshot in
            var groupId: UUID?
            if let groupName = snapshot.groupName, !groupName.isEmpty {
                let colorKey = snapshot.groupColorKey ?? TabGroup.defaultColorKey
                let descriptor = "\(groupName.lowercased())::\(colorKey)"
                let resolvedGroupId = groupIdsByDescriptor[descriptor] ?? {
                    let group = TabGroup(name: groupName, colorKey: colorKey)
                    restoredGroups.append(group)
                    groupIdsByDescriptor[descriptor] = group.id
                    return group.id
                }()
                groupId = resolvedGroupId
            }

            return BrowserTab(
                id: snapshot.id,
                url: snapshot.url,
                title: snapshot.title,
                favicon: snapshot.faviconUrl,
                groupId: groupId
            )
        }

        tabGroups = restoredGroups
        verticalTabsEnabled = !restoredGroups.isEmpty
        activeTabId = tabs.first?.id
        splitPrimaryTabId = nil
        splitTabId = nil
        currentURL = tabs.first?.url ?? newTabURL
        pruneEmptyGroups()
    }

    func restore(from snapshot: BrowserSessionSnapshot, newTabURL: String) {
        tabs = snapshot.tabs.map {
            BrowserTab(id: $0.id, url: $0.url, title: $0.title, favicon: $0.faviconUrl, groupId: $0.groupId)
        }
        tabGroups = snapshot.tabGroups.filter { group in
            tabs.contains(where: { $0.groupId == group.id })
        }
        verticalTabsEnabled = snapshot.verticalTabsEnabled
        activeTabId = snapshot.activeTabId ?? tabs.first?.id
        currentURL = currentTab?.url ?? tabs.first?.url ?? newTabURL
        splitPrimaryTabId = snapshot.splitPrimaryTabId
        splitTabId = snapshot.splitTabId
        pruneEmptyGroups()
    }

    func makeSessionSnapshot(newTabURL: String) -> BrowserSessionSnapshot {
        BrowserSessionSnapshot(
            tabs: sessionSnapshots(newTabURL: newTabURL),
            activeTabId: activeTabId,
            splitPrimaryTabId: splitPrimaryTabId,
            splitTabId: splitTabId,
            tabGroups: tabGroups,
            verticalTabsEnabled: verticalTabsEnabled,
            savedAt: Date()
        )
    }

    func toggleSplitView(newTabURL: String) {
        guard tabs.count >= 2, let activeTabId else {
            splitPrimaryTabId = nil
            splitTabId = nil
            return
        }

        if splitTabId != nil {
            splitPrimaryTabId = nil
            splitTabId = nil
            return
        }

        splitPrimaryTabId = activeTabId
        let candidate = tabs.first { $0.id != activeTabId && $0.url != newTabURL } ?? tabs.first { $0.id != activeTabId }
        splitTabId = candidate?.id
    }

    func setSplitTab(_ tabId: UUID?) {
        splitTabId = tabId
    }

    func availableSplitCandidates(newTabURL: String) -> [BrowserTab] {
        guard let primaryId = splitPrimaryTabId ?? activeTabId else { return [] }
        return tabs.filter { $0.id != primaryId && $0.url != newTabURL }
    }

    func toggleVerticalTabs() {
        verticalTabsEnabled.toggle()
    }

    func createGroupFromCurrentTab() {
        guard let currentTab else { return }
        if currentTab.groupId == nil {
            let group = TabGroup(
                name: suggestedGroupName(for: currentTab),
                colorKey: nextGroupColorKey()
            )
            tabGroups.append(group)
            assignTab(currentTab.id, to: group.id)
        } else if let group = group(for: currentTab.id),
                  let index = tabGroups.firstIndex(where: { $0.id == group.id }) {
            tabGroups[index].isCollapsed = false
        }
    }

    func assignTab(_ tabId: UUID, to groupId: UUID?) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        tabs[index].groupId = groupId
        pruneEmptyGroups()
    }

    func updateGroup(_ groupId: UUID, name: String, colorKey: String) {
        guard let index = tabGroups.firstIndex(where: { $0.id == groupId }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            tabGroups[index].name = trimmedName
        }
        if TabGroup.availableColorKeys.contains(colorKey) {
            tabGroups[index].colorKey = colorKey
        }
    }

    func moveTab(_ draggedTabId: UUID, toGroup targetGroupId: UUID?, before targetTabId: UUID? = nil) {
        guard let sourceIndex = tabs.firstIndex(where: { $0.id == draggedTabId }) else { return }

        var draggedTab = tabs.remove(at: sourceIndex)
        draggedTab.groupId = targetGroupId

        let insertionIndex: Int
        if let targetTabId,
           let index = tabs.firstIndex(where: { $0.id == targetTabId }) {
            insertionIndex = index
        } else if let targetGroupId {
            let targetIndices = tabs.indices.filter { tabs[$0].groupId == targetGroupId }
            insertionIndex = (targetIndices.last.map { $0 + 1 }) ?? tabs.count
        } else {
            let lastUngroupedIndex = tabs.indices.last(where: { tabs[$0].groupId == nil })
            insertionIndex = (lastUngroupedIndex.map { $0 + 1 }) ?? 0
        }

        tabs.insert(draggedTab, at: min(insertionIndex, tabs.count))
    }

    func reorderGroup(_ draggedGroupId: UUID, before targetGroupId: UUID) {
        guard draggedGroupId != targetGroupId,
              let sourceIndex = tabGroups.firstIndex(where: { $0.id == draggedGroupId }),
              let targetIndex = tabGroups.firstIndex(where: { $0.id == targetGroupId }) else { return }

        let group = tabGroups.remove(at: sourceIndex)
        let adjustedIndex = sourceIndex < targetIndex ? max(0, targetIndex - 1) : targetIndex
        tabGroups.insert(group, at: adjustedIndex)
    }

    func removeGroup(_ groupId: UUID) {
        for index in tabs.indices where tabs[index].groupId == groupId {
            tabs[index].groupId = nil
        }
        tabGroups.removeAll { $0.id == groupId }
    }

    func toggleGroupCollapsed(_ groupId: UUID) {
        guard let index = tabGroups.firstIndex(where: { $0.id == groupId }) else { return }
        tabGroups[index].isCollapsed.toggle()
    }

    func group(for tabId: UUID) -> TabGroup? {
        guard let tab = tabs.first(where: { $0.id == tabId }),
              let groupId = tab.groupId else { return nil }
        return tabGroups.first(where: { $0.id == groupId })
    }

    func tabs(in groupId: UUID) -> [BrowserTab] {
        tabs.filter { $0.groupId == groupId }
    }

    var ungroupedTabs: [BrowserTab] {
        tabs.filter { $0.groupId == nil }
    }

    var isSplitViewActive: Bool {
        splitTabId != nil
    }

    var splitPrimaryTab: BrowserTab? {
        guard let splitPrimaryTabId else { return nil }
        return tabs.first(where: { $0.id == splitPrimaryTabId })
    }

    var splitSecondaryTab: BrowserTab? {
        guard let splitTabId else { return nil }
        return tabs.first(where: { $0.id == splitTabId })
    }

    var currentTab: BrowserTab? {
        guard let activeTabId else { return nil }
        return tabs.first(where: { $0.id == activeTabId })
    }

    private func resetForEmptyState(newTabURL: String) {
        tabs = []
        activeTabId = nil
        currentURL = ""
        splitPrimaryTabId = nil
        splitTabId = nil
        tabGroups = []
        verticalTabsEnabled = false
        openNewTab(newTabURL: newTabURL)
    }

    private func pruneEmptyGroups() {
        let liveGroupIds = Set(tabs.compactMap(\.groupId))
        tabGroups.removeAll { !liveGroupIds.contains($0.id) }
    }

    private func suggestedGroupName(for tab: BrowserTab) -> String {
        if let host = URL(string: tab.url)?.host?
            .replacingOccurrences(of: "www.", with: "")
            .split(separator: ".")
            .first,
           !host.isEmpty {
            return host.capitalized
        }

        let cleanedTitle = tab.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedTitle.isEmpty, cleanedTitle != tab.url {
            return String(cleanedTitle.prefix(24))
        }

        return "Research Cluster"
    }

    private func nextGroupColorKey() -> String {
        let used = tabGroups.map(\.colorKey)
        return TabGroup.availableColorKeys.first(where: { !used.contains($0) }) ?? TabGroup.defaultColorKey
    }
}
