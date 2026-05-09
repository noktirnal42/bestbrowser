import SwiftUI

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
                NewTabHeroSection()

                NewTabSearchField(searchText: $searchText, onSubmit: submitSearch)

                HomeMetricsRow(
                    bookmarkCount: bookmarks.count,
                    recentPageCount: recentHistory.count,
                    workspaceCount: workspaceService.workspaces.count,
                    aiReady: aiClient.isAvailable
                )

                if let sessionBrief {
                    SessionBriefingSection(
                        suggestion: workspaceService.latestSessionTitleSuggestion,
                        brief: sessionBrief,
                        onSaveWorkspace: saveSessionAsWorkspace
                    )
                }

                if !organizer.suggestions.isEmpty {
                    HomePanelSection(title: "Suggested Workspaces") {
                        ForEach(organizer.suggestions.prefix(4)) { suggestion in
                            SuggestedWorkspaceRow(suggestion: suggestion)
                        }
                    }
                }

                HomePanelSection(title: "Saved Workspaces") {
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

                HomePanelSection(title: "Bookmarks") {
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

                HomePanelSection(title: "Recently Visited") {
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

    private var sessionBrief: String? {
        guard let brief = workspaceService.latestSessionBrief,
              !brief.isEmpty else {
            return nil
        }
        return brief
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

    private func submitSearch() {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return }
        onOpen(trimmedSearch)
    }

    private func saveSessionAsWorkspace() {
        Task {
            await workspaceService.createWorkspaceFromCurrentSession()
        }
    }
}
