import SwiftUI

struct BrowserInspectorView: View {
    @State private var selectedTab: InspectorTab = .history
    @StateObject private var storage = StorageManager.shared
    @StateObject private var search = SemanticSearch.shared

    @State private var searchQuery = ""
    @State private var historyEntries: [HistoryEntry] = []
    @State private var bookmarks: [Bookmark] = []
    @State private var searchResults: SmartSearchResults = .init(pages: [], history: [], memories: [], suggestions: [])

    @State private var isLoading = false

    enum InspectorTab: String, CaseIterable {
        case history = "History"
        case bookmarks = "Bookmarks"
        case search = "Search"
        case ai = "AI Tools"

        var icon: String {
            switch self {
            case .history: return "clock.fill"
            case .bookmarks: return "bookmark.fill"
            case .search: return "magnifyingglass"
            case .ai: return "sparkles"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Inspector")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Search your browsing trail, reopen pages fast, and run page-native AI tools.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(BestBrowserBrand.darkCard.opacity(0.8))

            HStack(spacing: 0) {
                ForEach(InspectorTab.allCases, id: \.self) { tab in
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab 
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                                .neonGlow(selectedTab == tab ? BestBrowserBrand.primary : .clear, radius: 4)

                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(selectedTab == tab ? BestBrowserBrand.primary : .gray)
                        .background(selectedTab == tab ? BestBrowserBrand.primary.opacity(0.1) : Color.clear)
                    }
                    .buttonStyle(.plain)
                    .help("Open \(tab.rawValue)")
                }
            }
            .background(BestBrowserBrand.darkCard)
            .border(BestBrowserBrand.border, width: 1)

            Divider().background(BestBrowserBrand.border)

            // Content
            contentForTab()
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), 
                                       removal: .move(edge: .leading).combined(with: .opacity)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BestBrowserBrand.darkBg)
        .frame(width: 280)
        .onAppear {
            loadHistory()
            loadBookmarks()
        }
    }

    private func loadHistory() {
        Task {
            if let entries = try? await storage.getHistory(limit: 50) {
                await MainActor.run {
                    historyEntries = entries
                }
            }
        }
    }

    private func loadBookmarks() {
        Task {
            if let bookmarks = try? await storage.getBookmarks() {
                await MainActor.run {
                    self.bookmarks = bookmarks
                }
            }
        }
    }

    @ViewBuilder
    private func contentForTab() -> some View {
        switch selectedTab {
        case .history:
            HistorySidebarView(entries: $historyEntries, storage: storage)
        case .bookmarks:
            BookmarksSidebarView(bookmarks: $bookmarks, storage: storage)
        case .search:
            SearchSidebarView(
                query: $searchQuery,
                results: $searchResults,
                search: search,
                isLoading: $isLoading
            )
        case .ai:
            AIToolsSidebarView()
        }
    }
}

#Preview {
    BrowserInspectorView()
}
