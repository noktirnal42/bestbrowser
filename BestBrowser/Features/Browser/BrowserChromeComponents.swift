import SwiftUI
import AppKit

struct SplitBrowserContentView: View {
    let primaryTab: BrowserTab
    let secondaryTab: BrowserTab
    let browserModel: BrowserViewModel

    var body: some View {
        HSplitView {
            splitPane(for: primaryTab, label: "Primary")
            splitPane(for: secondaryTab, label: "Reference")
        }
    }

    @ViewBuilder
    private func splitPane(for tab: BrowserTab, label: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
                Circle()
                    .fill(tab.id == browserModel.activeTabId ? BestBrowserBrand.secondary : BestBrowserBrand.border.opacity(0.5))
                    .frame(width: 6, height: 6)
                Text(tab.title.isEmpty ? tab.url : tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Button("Focus") {
                    browserModel.selectTab(tab.id)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BestBrowserBrand.chrome)
            .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.45)).frame(height: 1), alignment: .bottom)

            if browserModel.isNewTab(tab) {
                NewTabHomeView(
                    onOpen: { target in
                        browserModel.selectTab(tab.id)
                        browserModel.loadUrl(target, for: tab.id)
                    },
                    activeTabId: tab.id
                )
            } else {
                browserSurface(for: tab)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            browserModel.selectTab(tab.id)
        }
    }

    @ViewBuilder
    private func browserSurface(for tab: BrowserTab) -> some View {
        if browserModel.isYouTubeFocusedLiveMode(for: tab.id),
           let embedURL = browserModel.youTubeEmbedURL(for: tab) {
            YouTubeFocusedLiveView(
                tab: tab,
                embedURL: embedURL,
                browserModel: browserModel
            )
        } else {
            WebViewWrapper(url: tab.url, tabId: tab.id, viewModel: browserModel)
        }
    }
}

struct YouTubeFocusedLiveView: View {
    let tab: BrowserTab
    let embedURL: String
    let browserModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE FOCUS MODE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.secondary)
                    Text("YouTube live chat is blocked in this embedded browser, so BestBrowser is showing a clean player instead.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button("Standard Page") {
                    browserModel.disableYouTubeFocusedLiveMode(for: tab.id)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.border)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BestBrowserBrand.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BestBrowserBrand.border.opacity(0.6), lineWidth: 1)
                )

                Button("Open in Safari") {
                    guard let url = URL(string: tab.url) else { return }
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BestBrowserBrand.primary.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BestBrowserBrand.primary.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(BestBrowserBrand.chrome.opacity(0.96))
            .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.4)).frame(height: 1), alignment: .bottom)

            FocusedPlayerWebViewWrapper(
                url: embedURL,
                tabId: tab.id,
                viewModel: browserModel
            )
        }
        .background(BestBrowserBrand.darkBg)
    }
}

struct SplitTabPickerSheet: View {
    let tabs: [BrowserTab]
    let onSelect: (BrowserTab) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Second Tab")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            if tabs.isEmpty {
                Text("Open another page first, then try split view again.")
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(tabs) { tab in
                            Button(action: { onSelect(tab) }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tab.title.isEmpty ? tab.url : tab.title)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(tab.url)
                                            .font(.system(size: 11))
                                            .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "rectangle.split.2x1")
                                        .foregroundColor(BestBrowserBrand.secondary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BestBrowserBrand.raisedCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(BestBrowserBrand.border.opacity(0.75), lineWidth: 1)
                                )
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(BestBrowserBrand.border)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 320)
        .background(BestBrowserBrand.darkBg)
    }
}

struct ReadingModePayload: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let url: String
}

struct NewTabHomeView: View {
    let onOpen: (String) -> Void
    let activeTabId: UUID

    @StateObject private var storage = StorageManager.shared
    @StateObject private var aiClient = AIClient.shared
    @StateObject private var workspaceService = WorkspaceService.shared
    @ObservedObject private var organizer = TabOrganizer.shared
    @State private var searchText = ""
    @State private var recentHistory: [HistoryEntry] = []
    @State private var bookmarks: [Bookmark] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        if BrandGraphicView.exists(named: "launch-badge") {
                            BrandGraphicView(resourceName: "launch-badge", width: 84, height: 84)
                        } else {
                            AppIconView(size: 84)
                        }
                    }
                    Text("BestBrowser")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("A browser shaped for your own headspace.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                }

                HStack(spacing: 10) {
                    Text("PERSONAL BROWSER")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.secondary)
                    Capsule()
                        .fill(BestBrowserBrand.border.opacity(0.8))
                        .frame(width: 54, height: 1)
                    Text("quiet by default")
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.62))
                }

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(BestBrowserBrand.secondary)
                    TextField("Search the web or enter a URL", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.white)
                        .onSubmit {
                            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            onOpen(searchText)
                        }
                }
                .padding(14)
                .background(BestBrowserBrand.raisedCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(BestBrowserBrand.secondary.opacity(0.34), lineWidth: 1)
                )
                .cornerRadius(16)

                HStack(spacing: 12) {
                    HomeBadge(title: "Bookmarks", value: "\(bookmarks.count)", icon: "bookmark.fill")
                    HomeBadge(title: "Recent Pages", value: "\(recentHistory.count)", icon: "clock.fill")
                    HomeBadge(title: "Workspaces", value: "\(workspaceService.workspaces.count)", icon: "square.stack.3d.up.fill")
                    HomeBadge(title: "On-device AI", value: aiClient.isAvailable ? "Ready" : "Off", icon: "sparkles")
                }

                if let brief = workspaceService.latestSessionBrief, !brief.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Session Briefing")
                        VStack(alignment: .leading, spacing: 8) {
                            if let suggestion = workspaceService.latestSessionTitleSuggestion, !suggestion.isEmpty {
                                Text(suggestion)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text(brief)
                                .font(.system(size: 13))
                                .foregroundColor(BestBrowserBrand.fog.opacity(0.9))

                            Button(action: {
                                Task {
                                    await workspaceService.createWorkspaceFromCurrentSession()
                                }
                            }) {
                                Label("Save As Workspace", systemImage: "square.stack.badge.plus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(BestBrowserBrand.primary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BestBrowserBrand.cardBackground)
                        .cornerRadius(10)
                    }
                }

                if !organizer.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Suggested Workspaces")
                        ForEach(organizer.suggestions.prefix(4)) { suggestion in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(suggestion.groupName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                Text(suggestion.tabTitles.joined(separator: " • "))
                                    .font(.system(size: 11))
                                    .foregroundColor(BestBrowserBrand.fog.opacity(0.8))
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BestBrowserBrand.cardBackground)
                            .cornerRadius(10)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Saved Workspaces")
                    if workspaceService.workspaces.isEmpty {
                        EmptyCard(text: "Saved workspaces will appear here so you can jump back into a research session fast.")
                    } else {
                        ForEach(workspaceService.workspaces.prefix(4)) { workspace in
                            WorkspaceLaunchRow(workspace: workspace) {
                                Task { await workspaceService.openWorkspace(workspace) }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Bookmarks")
                    if bookmarks.isEmpty {
                        EmptyCard(text: "Save pages to bookmarks and they’ll appear here for quick access.")
                    } else {
                        ForEach(bookmarks.prefix(5)) { bookmark in
                            QuickLinkRow(title: bookmark.title, subtitle: bookmark.url) {
                                onOpen(bookmark.url)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Recently Visited")
                    if recentHistory.isEmpty {
                        EmptyCard(text: "As you browse, your recent pages will show up here for fast relaunch.")
                    } else {
                        ForEach(recentHistory.prefix(6)) { entry in
                            QuickLinkRow(title: entry.title.isEmpty ? entry.url : entry.title, subtitle: entry.url) {
                                onOpen(entry.url)
                            }
                        }
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [BestBrowserBrand.darkBg, BestBrowserBrand.darkCard.opacity(0.84)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [BestBrowserBrand.accent.opacity(0.12), .clear],
                    center: .topTrailing,
                    startRadius: 24,
                    endRadius: 560
                )

                RadialGradient(
                    colors: [BestBrowserBrand.secondary.opacity(0.10), .clear],
                    center: .bottomLeading,
                    startRadius: 18,
                    endRadius: 440
                )
            }
        )
        .task(id: activeTabId) {
            await loadData()
        }
    }

    private func loadData() async {
        if let history = try? await storage.getHistory(limit: 6) {
            recentHistory = history.filter { $0.url != BrowserViewModel.newTabURL }
        }
        if let saved = try? await storage.getBookmarks() {
            bookmarks = saved
        }
        await workspaceService.refresh()
        await workspaceService.refreshSessionInsights()

        let tabs = BrowserViewModel.shared.tabs
            .filter { !$0.title.isEmpty && $0.url != BrowserViewModel.newTabURL }
            .map { ($0.title, $0.url) }

        await organizer.generateSuggestions(for: tabs)
    }

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(BestBrowserBrand.border)
    }
}

private struct WorkspaceLaunchRow: View {
    let workspace: Workspace
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workspace.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(workspace.summary ?? workspace.purpose ?? "Saved browsing session")
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "arrow.clockwise.circle")
                    .foregroundColor(BestBrowserBrand.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.cardBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

private struct HomeBadge: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(BestBrowserBrand.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BestBrowserBrand.raisedCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

private struct QuickLinkRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundColor(BestBrowserBrand.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(14)
    }
}

// MARK: - Tab Bar

struct TabBarView: View {
    let tabs: [BrowserTab]
    let groups: [TabGroup]
    let activeTabId: UUID?
    let onSelectTab: (UUID) -> Void
    let onCloseTab: (UUID) -> Void
    let onNewTab: () -> Void
    let onCreateGroup: () -> Void
    let onToggleVerticalTabs: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("Sessions")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.5))
                .padding(.leading, 10)
                .padding(.trailing, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == activeTabId,
                            onSelect: { onSelectTab(tab.id) },
                            onClose: { onCloseTab(tab.id) }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 40)

            Button(action: onNewTab) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("New")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(BestBrowserBrand.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BestBrowserBrand.secondary.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(BestBrowserBrand.secondary.opacity(0.45), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 6)

            if !tabs.isEmpty {
                Button(action: onCreateGroup) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BestBrowserBrand.secondary)
                        .padding(8)
                        .background(BestBrowserBrand.raisedCard)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Group current tab")
            }

            Button(action: onToggleVerticalTabs) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BestBrowserBrand.primary)
                    .padding(8)
                    .background(BestBrowserBrand.raisedCard)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Switch to vertical tabs")
            .padding(.horizontal, 10)
        }
        .background(BestBrowserBrand.chrome)
    }
}

struct TabItemView: View {
    let tab: BrowserTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            FaviconView(faviconURL: tab.favicon, isActive: isActive)

            Text(tab.title)
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(1)
                .foregroundColor(isActive ? .white : BestBrowserBrand.fog.opacity(0.72))

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? BestBrowserBrand.secondary.opacity(0.18) : BestBrowserBrand.raisedCard.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? BestBrowserBrand.secondary.opacity(0.45) : BestBrowserBrand.border.opacity(0.55), lineWidth: 1)
        )
        .cornerRadius(10)
        .onTapGesture(perform: onSelect)
    }
}

private struct FaviconView: View {
    let faviconURL: String?
    let isActive: Bool

    var body: some View {
        if let faviconURL,
           let url = URL(string: faviconURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                default:
                    fallback
                }
            }
            .frame(width: 12, height: 12)
        } else {
            fallback
        }
    }

    private var fallback: some View {
        Image(systemName: "globe")
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .foregroundColor(isActive ? BestBrowserBrand.primary : BestBrowserBrand.border)
    }
}

struct VerticalTabRailView: View {
    let tabs: [BrowserTab]
    let groups: [TabGroup]
    let activeTabId: UUID?
    let onSelectTab: (UUID) -> Void
    let onCloseTab: (UUID) -> Void
    let onNewTab: () -> Void
    let onToggleSidebar: () -> Void
    let onToggleVerticalTabs: () -> Void
    let onCreateGroup: () -> Void
    let onAssignTabToGroup: (UUID, UUID?) -> Void
    let onMoveTab: (UUID, UUID?, UUID?) -> Void
    let onToggleGroup: (UUID) -> Void
    let onRemoveGroup: (UUID) -> Void
    let onEditGroup: (TabGroup) -> Void
    let onReorderGroup: (UUID, UUID) -> Void
    @State private var ungroupedDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tab Rail")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.secondary)
                    Text("\(tabs.count) open")
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.72))
                }

                Spacer()

                HStack(spacing: 6) {
                    railIconButton(icon: "sidebar.left", action: onToggleSidebar)
                    railIconButton(icon: "plus", action: onNewTab)
                    railIconButton(icon: "square.stack.3d.up.fill", action: onCreateGroup)
                    railIconButton(icon: "rectangle.tophalf.inset.filled", action: onToggleVerticalTabs)
                }
            }
            .padding(12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !ungroupedTabs.isEmpty {
                        railSectionLabel("Ungrouped")
                        VStack(spacing: 6) {
                            ForEach(ungroupedTabs) { tab in
                                VerticalTabRow(
                                    tab: tab,
                                    isActive: tab.id == activeTabId,
                                    tint: BestBrowserBrand.border,
                                    availableGroups: groups,
                                    onSelect: { onSelectTab(tab.id) },
                                    onClose: { onCloseTab(tab.id) },
                                    onAssignToGroup: { groupId in
                                        onAssignTabToGroup(tab.id, groupId)
                                    },
                                    onDropTabBefore: { draggedTabId in
                                        onMoveTab(draggedTabId, nil, tab.id)
                                    }
                                )
                            }
                        }
                        .padding(8)
                        .background(ungroupedDropTargeted ? BestBrowserBrand.primary.opacity(0.08) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    ungroupedDropTargeted ? BestBrowserBrand.primary.opacity(0.55) : BestBrowserBrand.border.opacity(0.2),
                                    style: StrokeStyle(lineWidth: ungroupedDropTargeted ? 1.4 : 1, dash: ungroupedDropTargeted ? [5, 4] : [])
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .dropDestination(
                            for: String.self,
                            action: { items, _ in
                                return handleDrop(items: items, targetGroup: nil, targetTab: nil)
                            },
                            isTargeted: { isTargeted in
                                ungroupedDropTargeted = isTargeted
                            }
                        )
                    }

                    ForEach(groups) { group in
                        let groupTabs = tabs.filter { $0.groupId == group.id }
                        if !groupTabs.isEmpty {
                            VerticalTabGroupSection(
                                group: group,
                                groupTabs: groupTabs,
                                allGroups: groups,
                                activeTabId: activeTabId,
                                tint: groupColor(for: group.colorKey),
                                onSelectTab: onSelectTab,
                                onCloseTab: onCloseTab,
                                onAssignTabToGroup: onAssignTabToGroup,
                                onMoveTab: onMoveTab,
                                onToggleGroup: onToggleGroup,
                                onRemoveGroup: onRemoveGroup,
                                onEditGroup: onEditGroup,
                                onReorderGroup: onReorderGroup
                            )
                        }
                    }
                }
                .padding(12)
            }
        }
    }

    private var ungroupedTabs: [BrowserTab] {
        tabs.filter { $0.groupId == nil }
    }

    @ViewBuilder
    private func railSectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(BestBrowserBrand.fog.opacity(0.55))
    }

    @ViewBuilder
    private func railIconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(BestBrowserBrand.primary)
                .padding(8)
                .background(BestBrowserBrand.raisedCard)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func groupColor(for key: String) -> Color {
        switch key {
        case "sky": return BestBrowserBrand.primary
        case "blue": return BestBrowserBrand.accent
        case "mint": return BestBrowserBrand.success
        case "rose": return BestBrowserBrand.warning
        default: return BestBrowserBrand.secondary
        }
    }

    private func handleDrop(items: [String], targetGroup: UUID?, targetTab: UUID?) -> Bool {
        guard let payload = items.first else { return false }

        if payload.hasPrefix("tab:"),
           let draggedTabId = UUID(uuidString: String(payload.dropFirst(4))) {
            if let targetTab {
                onMoveTab(draggedTabId, targetGroup, targetTab)
            } else {
                onMoveTab(draggedTabId, targetGroup, nil)
            }
            return true
        }

        if payload.hasPrefix("group:"),
           let targetGroup,
           let draggedGroupId = UUID(uuidString: String(payload.dropFirst(6))) {
            onReorderGroup(draggedGroupId, targetGroup)
            return true
        }

        return false
    }
}

private struct VerticalTabGroupSection: View {
    let group: TabGroup
    let groupTabs: [BrowserTab]
    let allGroups: [TabGroup]
    let activeTabId: UUID?
    let tint: Color
    let onSelectTab: (UUID) -> Void
    let onCloseTab: (UUID) -> Void
    let onAssignTabToGroup: (UUID, UUID?) -> Void
    let onMoveTab: (UUID, UUID?, UUID?) -> Void
    let onToggleGroup: (UUID) -> Void
    let onRemoveGroup: (UUID) -> Void
    let onEditGroup: (TabGroup) -> Void
    let onReorderGroup: (UUID, UUID) -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button(action: { onToggleGroup(group.id) }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(tint)
                            .frame(width: 8, height: 8)
                        Text(group.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(groupTabs.count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.fog.opacity(0.72))
                        Image(systemName: group.isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(BestBrowserBrand.border)
                    }
                }
                .buttonStyle(.plain)
                .draggable(groupDragPayload(for: group))
                .dropDestination(
                    for: String.self,
                    action: { items, _ in
                        return handleDrop(items: items, targetGroup: group.id, targetTab: nil)
                    },
                    isTargeted: { isTargeted in
                        self.isDropTargeted = isTargeted
                    }
                )

                Menu {
                    Button("Edit Group") {
                        onEditGroup(group)
                    }

                    Divider()

                    Button("Ungroup Tabs", role: .destructive) {
                        onRemoveGroup(group.id)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(BestBrowserBrand.border)
                }
                .menuStyle(.borderlessButton)
            }

            if !group.isCollapsed {
                VStack(spacing: 6) {
                    ForEach(groupTabs) { tab in
                        VerticalTabRow(
                            tab: tab,
                            isActive: tab.id == activeTabId,
                            tint: tint,
                            availableGroups: allGroups,
                            onSelect: { onSelectTab(tab.id) },
                            onClose: { onCloseTab(tab.id) },
                            onAssignToGroup: { targetGroupId in
                                onAssignTabToGroup(tab.id, targetGroupId)
                            },
                            onDropTabBefore: { draggedTabId in
                                onMoveTab(draggedTabId, group.id, tab.id)
                            }
                        )
                    }
                }
            }
        }
        .padding(8)
        .background(isDropTargeted ? tint.opacity(0.08) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isDropTargeted ? tint.opacity(0.7) : BestBrowserBrand.border.opacity(0.18),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 1.4 : 1, dash: isDropTargeted ? [5, 4] : [])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func handleDrop(items: [String], targetGroup: UUID?, targetTab: UUID?) -> Bool {
        guard let payload = items.first else { return false }

        if payload.hasPrefix("tab:"),
           let draggedTabId = UUID(uuidString: String(payload.dropFirst(4))) {
            onMoveTab(draggedTabId, targetGroup, targetTab)
            return true
        }

        if payload.hasPrefix("group:"),
           let targetGroup,
           let draggedGroupId = UUID(uuidString: String(payload.dropFirst(6))) {
            onReorderGroup(draggedGroupId, targetGroup)
            return true
        }

        return false
    }

    private func groupDragPayload(for group: TabGroup) -> String {
        "group:\(group.id.uuidString)"
    }
}

private struct VerticalTabRow: View {
    let tab: BrowserTab
    let isActive: Bool
    let tint: Color
    let availableGroups: [TabGroup]
    let onSelect: () -> Void
    let onClose: () -> Void
    let onAssignToGroup: (UUID?) -> Void
    let onDropTabBefore: (UUID) -> Void
    @State private var isDropTargeted = false

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isActive ? tint : tint.opacity(0.35))
                .frame(width: 4, height: 26)

            FaviconView(faviconURL: tab.favicon, isActive: isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title.isEmpty ? "Untitled Tab" : tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isActive ? .white : BestBrowserBrand.fog.opacity(0.9))
                    .lineLimit(1)

                Text(tab.url)
                    .font(.system(size: 10))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Menu {
                if !availableGroups.isEmpty {
                    ForEach(availableGroups) { group in
                        Button(group.name) {
                            onAssignToGroup(group.id)
                        }
                    }

                    Divider()
                }

                Button("Remove from Group") {
                    onAssignToGroup(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 12))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .menuStyle(.borderlessButton)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isDropTargeted
                ? tint.opacity(0.12)
                : (isActive ? BestBrowserBrand.raisedCard : BestBrowserBrand.cardBackground.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isDropTargeted
                        ? tint.opacity(0.78)
                        : (isActive ? tint.opacity(0.45) : BestBrowserBrand.border.opacity(0.42)),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 1.5 : 1, dash: isDropTargeted ? [5, 4] : [])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onSelect)
        .draggable("tab:\(tab.id.uuidString)")
        .dropDestination(
            for: String.self,
            action: { items, _ in
                guard let payload = items.first,
                      payload.hasPrefix("tab:"),
                      let draggedTabId = UUID(uuidString: String(payload.dropFirst(4))),
                      draggedTabId != tab.id else {
                    return false
                }
                onDropTabBefore(draggedTabId)
                return true
            },
            isTargeted: { isTargeted in
                self.isDropTargeted = isTargeted
            }
        )
    }
}

struct EditTabGroupSheet: View {
    let group: TabGroup
    let onSave: (String, String) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var colorKey: String

    init(
        group: TabGroup,
        onSave: @escaping (String, String) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.group = group
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _name = State(initialValue: group.name)
        _colorKey = State(initialValue: group.colorKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit Tab Group")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
                TextField("Group name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)

                HStack(spacing: 10) {
                    ForEach(TabGroup.availableColorKeys, id: \.self) { key in
                        Button(action: { colorKey = key }) {
                            Circle()
                                .fill(groupColor(for: key))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .stroke(colorKey == key ? Color.white : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button("Delete Group", role: .destructive, action: onDelete)
                Spacer()
                Button("Cancel", action: onCancel)
                Button("Save") {
                    onSave(name, colorKey)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(minWidth: 360)
        .background(BestBrowserBrand.darkBg)
    }

    private func groupColor(for key: String) -> Color {
        switch key {
        case "sky": return BestBrowserBrand.primary
        case "blue": return BestBrowserBrand.accent
        case "mint": return BestBrowserBrand.success
        case "rose": return BestBrowserBrand.warning
        default: return BestBrowserBrand.secondary
        }
    }
}

// MARK: - Branded Toolbar

struct BrandedToolbarView: View {
    let url: String
    let canGoBack: Bool
    let canGoForward: Bool
    let focusedTabTitle: String
    let focusedPaneLabel: String
    let onBack: () -> Void
    let onForward: () -> Void
    let onRefresh: () -> Void
    let onUrlChanged: (String) -> Void
    let onShowSettings: () -> Void
    let onOpenReadingMode: () -> Void
    let onRepairVideoLayout: () -> Void
    let onOpenDownloads: () -> Void
    let currentTabHasMedia: Bool
    let currentTabVolume: Double
    let currentTabMuted: Bool
    let onSetCurrentTabVolume: (Double) -> Void
    let onToggleCurrentTabMuted: () -> Void
    let isVideoPaneVisible: Bool
    let onToggleVideoPane: () -> Void
    let onResetVideoPane: () -> Void
    let toolbarExtensions: [BrowserExtension]
    let onRunExtension: (BrowserExtension) -> Void
    let onShowSplitPicker: () -> Void
    let recentClosedTabs: [ClosedTabRecord]
    let recentClosedSessions: [ClosedSessionRecord]
    let onReopenClosedTab: () -> Void
    let onReopenSpecificClosedTab: (ClosedTabRecord) -> Void
    let onRestoreClosedSession: (ClosedSessionRecord) -> Void

    @State private var urlText: String = ""
    @FocusState private var urlFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(focusedPaneLabel.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.secondary)
                Text(focusedTabTitle.isEmpty ? "Untitled Page" : focusedTabTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.82))
                    .lineLimit(1)
            }
            .frame(width: 170, alignment: .leading)
            .padding(.leading, 2)

            HStack(spacing: 4) {
                NavButton(icon: "chevron.left", enabled: canGoBack, helpText: "Back") { onBack() }
                NavButton(icon: "chevron.right", enabled: canGoForward, helpText: "Forward") { onForward() }
                NavButton(icon: "arrow.clockwise", enabled: true, helpText: "Reload page") { onRefresh() }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                Capsule().stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
            )
            .clipShape(Capsule())

            HStack(spacing: 8) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.secondary)

                TextField("Search or enter URL", text: $urlText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.primary)
                    .focused($urlFocused)
                    .onSubmit {
                        onUrlChanged(urlText)
                        urlFocused = false
                    }

                if !urlText.isEmpty && urlFocused {
                    Button(action: { urlText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(BestBrowserBrand.border)
                    }
                    .buttonStyle(.plain)
                }

                if url.hasPrefix("https://") {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(BestBrowserBrand.success)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(urlFocused ? BestBrowserBrand.secondary.opacity(0.52) : BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(18)

            HStack(spacing: 4) {
                Text(url.hasPrefix("https://") ? "Secure" : "Open")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(url.hasPrefix("https://") ? BestBrowserBrand.success : BestBrowserBrand.border)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                Capsule().stroke(BestBrowserBrand.border.opacity(0.7), lineWidth: 1)
            )
            .clipShape(Capsule())

                Button(action: onOpenReadingMode) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .buttonStyle(.plain)
                .help("Open Reading Mode")

            if url.contains("youtube.com/watch") {
                Button(action: onRepairVideoLayout) {
                    Image(systemName: "rectangle.compress.vertical")
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.secondary)
                }
                .buttonStyle(.plain)
                .help("Repair YouTube layout")
            }

            Button(action: onOpenDownloads) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.primary)
            }
            .buttonStyle(.plain)
            .help("Open Downloads")

            HStack(spacing: 8) {
                Button(action: onToggleCurrentTabMuted) {
                    Image(systemName: currentTabMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(currentTabHasMedia ? (currentTabMuted ? BestBrowserBrand.warning : BestBrowserBrand.primary) : BestBrowserBrand.border)
                }
                .buttonStyle(.plain)
                .disabled(!currentTabHasMedia)
                .help(currentTabHasMedia ? (currentTabMuted ? "Unmute current tab" : "Mute current tab") : "No media detected in the current tab")

                Slider(
                    value: Binding(
                        get: { currentTabVolume },
                        set: { value in onSetCurrentTabVolume(value) }
                    ),
                    in: 0...1
                )
                .frame(width: 90)
                .disabled(!currentTabHasMedia)
                .help(currentTabHasMedia ? "Current tab volume" : "No media detected in the current tab")
            }

            Button(action: onToggleVideoPane) {
                Image(systemName: isVideoPaneVisible ? "play.tv.fill" : "play.tv")
                    .font(.system(size: 11))
                    .foregroundColor(isVideoPaneVisible ? BestBrowserBrand.secondary : BestBrowserBrand.border)
            }
            .buttonStyle(.plain)
            .help(isVideoPaneVisible ? "Hide video pane" : "Show video pane")

            Button(action: onResetVideoPane) {
                Image(systemName: "arrow.up.left.and.arrow.down.right.circle")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .buttonStyle(.plain)
            .help("Reset floating video pane position")

            if toolbarExtensions.count <= 2 {
                ForEach(toolbarExtensions) { ext in
                    Button(action: { onRunExtension(ext) }) {
                        Image(systemName: ext.icon)
                            .font(.system(size: 11))
                            .foregroundColor(BestBrowserBrand.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(ext.name)
                }
            } else if !toolbarExtensions.isEmpty {
                Menu {
                    ForEach(toolbarExtensions) { ext in
                        Button(action: { onRunExtension(ext) }) {
                            Label(ext.name, systemImage: ext.icon)
                        }
                    }
                } label: {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.secondary)
                }
                .menuStyle(.borderlessButton)
                .help("Page tools")
            }

            Button(action: onShowSplitPicker) {
                Image(systemName: "rectangle.split.2x1")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.primary)
            }
            .buttonStyle(.plain)
            .help("Open Split View")

            Menu {
                Button(action: onReopenClosedTab) {
                    Label("Reopen Last Closed Tab", systemImage: "arrow.uturn.backward")
                }
                .disabled(recentClosedTabs.isEmpty)

                if !recentClosedTabs.isEmpty {
                    Divider()
                    ForEach(recentClosedTabs.prefix(8)) { tab in
                        Button(action: { onReopenSpecificClosedTab(tab) }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tab.title.isEmpty ? tab.url : tab.title)
                                Text(tab.url)
                            }
                        }
                    }
                }

                if !recentClosedSessions.isEmpty {
                    Divider()
                    ForEach(recentClosedSessions.prefix(6)) { session in
                        Button(action: { onRestoreClosedSession(session) }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Restore: \(session.title)")
                                Text("\(session.snapshot.tabs.count) tabs • \(session.closedAt.formatted(date: .omitted, time: .shortened))")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.primary)
            }
            .menuStyle(.borderlessButton)
            .help("Recently closed tabs and sessions")

            Button(action: onShowSettings) {
                Image(systemName: "gear")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(8)
        .background(BestBrowserBrand.chrome)
        .onChange(of: url) { _, newValue in urlText = newValue }
        .onAppear { urlText = url }
        .onReceive(NotificationCenter.default.publisher(for: .focusURLBar)) { _ in
            urlFocused = true
            urlText = ""
        }
    }
}

struct NavButton: View {
    let icon: String
    let enabled: Bool
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(enabled ? BestBrowserBrand.primary : BestBrowserBrand.border.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(helpText)
    }
}
