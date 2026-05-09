import SwiftUI

struct MainColumnTopChrome: View {
    @ObservedObject var browserModel: BrowserViewModel
    @ObservedObject var shellStore: BrowserShellStore
    let commandCoordinator: BrowserCommandCoordinator
    @ObservedObject var extensionHost: BrowserExtensionHost
    @ObservedObject var videoStore: VideoPlayerStore

    var body: some View {
        if !shellStore.focusMode {
            if !browserModel.verticalTabsEnabled {
                MainColumnTabStrip(
                    browserModel: browserModel,
                    shellStore: shellStore
                )
            }

            BrandedToolbarView(
                url: browserModel.url,
                canGoBack: browserModel.canGoBack,
                canGoForward: browserModel.canGoForward,
                focusedTabTitle: browserModel.currentTab?.title ?? "No Tab",
                focusedPaneLabel: focusedPaneLabel,
                onBack: { browserModel.goBack() },
                onForward: { browserModel.goForward() },
                onRefresh: { browserModel.refresh() },
                onUrlChanged: { browserModel.loadUrl($0) },
                onShowSettings: { shellStore.presentSettings() },
                onOpenReadingMode: { commandCoordinator.execute(BrowserCommand.openReadingMode) },
                onRepairVideoLayout: { commandCoordinator.execute(BrowserCommand.repairVideoLayout) },
                onOpenDownloads: { commandCoordinator.execute(BrowserCommand.openDownloads) },
                currentTabHasMedia: browserModel.currentTabHasMedia,
                currentTabVolume: browserModel.currentMediaVolume,
                currentTabMuted: browserModel.currentMediaMuted,
                onSetCurrentTabVolume: { browserModel.setCurrentTabVolume($0) },
                onToggleCurrentTabMuted: { browserModel.toggleCurrentTabMuted() },
                isVideoPaneVisible: videoStore.isPinnedPaneVisible,
                onToggleVideoPane: toggleVideoPane,
                onResetVideoPane: { videoStore.resetPaneOffset() },
                toolbarExtensions: extensionHost.toolbarExtensions(for: URL(string: browserModel.url)),
                onRunExtension: { extensionHost.run($0) },
                onShowSplitPicker: {
                    shellStore.presentSplitPicker(primaryTabId: browserModel.activeTabId)
                },
                recentClosedTabs: browserModel.closedTabs,
                recentClosedSessions: browserModel.closedSessions,
                onReopenClosedTab: { browserModel.reopenClosedTab() },
                onReopenSpecificClosedTab: { record in
                    browserModel.reopenClosedTab(record)
                },
                onRestoreClosedSession: { record in
                    browserModel.restoreClosedSession(record)
                }
            )
        }
    }

    private var focusedPaneLabel: String {
        if browserModel.isSplitViewActive {
            return browserModel.activeTabId == browserModel.splitPrimaryTabId ? "Primary Pane" : "Reference Pane"
        }
        return browserModel.group(for: browserModel.activeTabId ?? UUID())?.name ?? "Single Page"
    }

    private func toggleVideoPane() {
        if videoStore.isPinnedPaneVisible {
            videoStore.setPinnedPaneVisible(false)
        } else {
            videoStore.resetPaneOffset()
            videoStore.setPinnedPaneVisible(true)
            if videoStore.isPinnedPaneCollapsed {
                videoStore.togglePinnedPaneCollapsed()
            }
        }
    }
}

private struct MainColumnTabStrip: View {
    @ObservedObject var browserModel: BrowserViewModel
    @ObservedObject var shellStore: BrowserShellStore

    var body: some View {
        HStack(spacing: 4) {
            TabBarView(
                tabs: browserModel.tabs,
                groups: browserModel.tabGroups,
                activeTabId: browserModel.activeTabId,
                onSelectTab: { browserModel.selectTab($0) },
                onCloseTab: { browserModel.closeTab(id: $0) },
                onNewTab: { browserModel.newTab() },
                onCreateGroup: { browserModel.createGroupFromCurrentTab() },
                onToggleVerticalTabs: { browserModel.toggleVerticalTabs() }
            )

            Button(action: {
                withAnimation(.spring()) { shellStore.toggleSidebar() }
            }) {
                Image(systemName: shellStore.showSidebar ? "sidebar.left" : "sidebar.left.2")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(shellStore.showSidebar ? BestBrowserBrand.primary : BestBrowserBrand.border)
                    .padding(6)
                    .background(BestBrowserBrand.cardBackground)
                    .cornerRadius(4)
                    .border(BestBrowserBrand.border, width: 0.5)
            }
            .buttonStyle(.plain)
            .help(shellStore.showSidebar ? "Hide the inspector sidebar" : "Show the inspector sidebar")
            .padding(.horizontal, 8)
        }
        .background(BestBrowserBrand.darkCard)
        .border(BestBrowserBrand.border, width: 1)
    }
}

struct MainColumnContentSurface: View {
    @ObservedObject var browserModel: BrowserViewModel

    var body: some View {
        Group {
            if browserModel.isSplitViewActive,
               let primary = browserModel.splitPrimaryTab,
               let secondary = browserModel.splitSecondaryTab {
                SplitBrowserContentView(
                    primaryTab: primary,
                    secondaryTab: secondary,
                    browserModel: browserModel
                )
            } else {
                ZStack {
                    ForEach(browserModel.tabs) { tab in
                        MainColumnTabSurface(tab: tab, browserModel: browserModel)
                            .opacity(tab.id == browserModel.activeTabId ? 1 : 0)
                            .allowsHitTesting(tab.id == browserModel.activeTabId)
                            .zIndex(tab.id == browserModel.activeTabId ? 1 : 0)
                    }
                }
            }
        }
        .background(BestBrowserBrand.darkBg)
    }
}

private struct MainColumnTabSurface: View {
    let tab: BrowserTab
    @ObservedObject var browserModel: BrowserViewModel

    var body: some View {
        if browserModel.isNewTab(tab) {
            NewTabHomeView(
                onOpen: { browserModel.openInCurrentTab($0) },
                activeTabId: tab.id
            )
        } else if browserModel.isYouTubeFocusedLiveMode(for: tab.id),
                  let embedURL = browserModel.youTubeEmbedURL(for: tab) {
            YouTubeFocusedLiveView(
                tab: tab,
                embedURL: embedURL,
                browserModel: browserModel
            )
        } else {
            WebViewWrapper(
                url: tab.url,
                tabId: tab.id,
                viewModel: browserModel
            )
        }
    }
}

struct FocusModeBanner: View {
    @ObservedObject var shellStore: BrowserShellStore

    var body: some View {
        if shellStore.focusMode {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { shellStore.exitFocusMode() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Exit Focus")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(BestBrowserBrand.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(BestBrowserBrand.primary.opacity(0.1))
                        .border(BestBrowserBrand.primary, width: 1)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "shield.leeward.fill")
                            .foregroundColor(BestBrowserBrand.success)
                            .font(.system(size: 11))
                        Text("Privacy Shield Active")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.success)
                    }
                }
                .padding(8)
                .background(BestBrowserBrand.darkCard.opacity(0.9))
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
