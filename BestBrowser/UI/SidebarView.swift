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

// MARK: - AI Tools Panel

struct AIToolsSidebarView: View {
    @StateObject private var aiClient = AIClient.shared
    @State private var isProcessing = false
    @State private var aiResult: String?
    @State private var autoSummarize = false
    @State private var contentInspectorActive = true

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(BestBrowserBrand.secondary)
                    .neonGlow(BestBrowserBrand.secondary, radius: 3)
                Text("AI ASSISTANT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
                Spacer()
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(BestBrowserBrand.primary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if !aiClient.isAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    Text("APPLE INTELLIGENCE REQUIRED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.warning)

                    Text(unavailableMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(BestBrowserBrand.darkCard)
                .border(BestBrowserBrand.warning, width: 0.5)
                .cornerRadius(6)
                .padding(.horizontal, 8)
            }

            VStack(spacing: 6) {
                AIToolButton(title: "Summarize Page", icon: "doc.text.magnifyingglass", isLoading: isProcessing) {
                    performAIAction(.summarize)
                }
                .disabled(!aiClient.isAvailable)
                AIToolButton(title: "Extract Key Points", icon: "list.bullet.indent", isLoading: isProcessing) {
                    performAIAction(.keyPoints)
                }
                .disabled(!aiClient.isAvailable)
                AIToolButton(title: "Translate Page", icon: "text.bubble", isLoading: isProcessing) {
                    performAIAction(.translate)
                }
                .disabled(!aiClient.isAvailable)
                AIToolButton(title: "Simplify Text", icon: "wand.magic", isLoading: isProcessing) {
                    performAIAction(.simplify)
                }
                .disabled(!aiClient.isAvailable)
            }
            .padding(.horizontal, 8)

            Divider().background(BestBrowserBrand.border)

            HStack(spacing: 6) {
                Image(systemName: "eye.slash.fill")
                    .foregroundColor(BestBrowserBrand.error)
                    .neonGlow(BestBrowserBrand.error, radius: 3)
                Text("CONTENT INSPECTOR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)

            VStack(spacing: 6) {
                AIToolButton(title: "Remove Ads & Noise", icon: "xmark.shield.fill", isLoading: false) {
                    performAIAction(.cleanPage)
                }
                AIToolButton(title: "Block Trackers", icon: "hand.raised.fill", isLoading: false) {
                    performAIAction(.blockTrackers)
                }
                AIToolButton(title: "Strip Popups", icon: "rectangle.xmark", isLoading: false) {
                    performAIAction(.stripPopups)
                }
            }
            .padding(.horizontal, 8)

            Toggle("Auto Content Inspector", isOn: $contentInspectorActive)
                .font(.system(size: 11, design: .monospaced))
                .tint(BestBrowserBrand.success)
                .padding(.horizontal, 8)

            Toggle("Auto-Summarize Pages", isOn: $autoSummarize)
                .font(.system(size: 11, design: .monospaced))
                .tint(BestBrowserBrand.primary)
                .padding(.horizontal, 8)
                .disabled(!aiClient.isAvailable)

            if let result = aiResult {
                ScrollView {
                    Text(result)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.primary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BestBrowserBrand.cardBackground)
                        .border(BestBrowserBrand.border, width: 0.5)
                        .cornerRadius(6)
                }
                .padding(.horizontal, 8)
                .frame(maxHeight: 200)
            }

            Spacer()
        }
    }

    private enum AIAction {
        case summarize, keyPoints, translate, simplify, cleanPage, blockTrackers, stripPopups
    }

    private func performAIAction(_ action: AIAction) {
        isProcessing = true
        aiResult = nil

        Task {
            let summarizer = ContentSummarizer.shared
            let privacyShield = PrivacyShield.shared

            if [.summarize, .keyPoints, .translate, .simplify].contains(action),
               !aiClient.isAvailable {
                aiResult = unavailableMessage
                isProcessing = false
                return
            }

            switch action {
            case .summarize:
                if let content = await BrowserViewModel.shared.currentPageContent() {
                    do {
                        let summary = try await summarizer.summarize(content, style: .concise)
                        aiResult = summary
                    } catch {
                        aiResult = "Error: \(error.localizedDescription)"
                    }
                } else {
                    aiResult = "Navigate to a page first to summarize its content."
                }

            case .keyPoints:
                if let content = await BrowserViewModel.shared.currentPageContent() {
                    do {
                        let points = try await summarizer.extractKeyPoints(content)
                        aiResult = points.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
                    } catch {
                        aiResult = "Error: \(error.localizedDescription)"
                    }
                } else {
                    aiResult = "Navigate to a page first."
                }

            case .translate:
                if let content = await BrowserViewModel.shared.currentPageContent() {
                    do {
                        let prompt = "Translate the following text to English if it's in another language, or to Spanish if it's in English. Provide only the translation:\n\n\(String(content.prefix(5000)))"
                        let messages: [[String: String]] = [["role": "user", "content": prompt]]
                        let result = try await AIClient.shared.chat(messages, maxTokens: 800)
                        aiResult = result
                    } catch {
                        aiResult = "Error: \(error.localizedDescription)"
                    }
                } else {
                    aiResult = "Navigate to a page first."
                }

            case .simplify:
                if let content = await BrowserViewModel.shared.currentPageContent() {
                    do {
                        let prompt = "Simplify the following text to be easy to understand for a general audience. Use simple words and short sentences:\n\n\(String(content.prefix(5000)))"
                        let messages: [[String: String]] = [["role": "user", "content": prompt]]
                        let result = try await AIClient.shared.chat(messages, maxTokens: 800)
                        aiResult = result
                    } catch {
                        aiResult = "Error: \(error.localizedDescription)"
                    }
                } else {
                    aiResult = "Navigate to a page first."
                }

            case .cleanPage:
                NotificationCenter.default.post(name: .cleanPageContent, object: nil)
                aiResult = "Content cleaning activated — ads, banners, and noise elements will be removed from the current page."

            case .blockTrackers:
                if !privacyShield.trackerBlockingEnabled {
                    privacyShield.toggleTrackerBlocking()
                }
                NotificationCenter.default.post(name: .blockTrackersNow, object: nil)
                aiResult = "Tracker blocking enhanced. \(privacyShield.stats.trackersBlocked) trackers blocked this session."

            case .stripPopups:
                NotificationCenter.default.post(name: .stripPopupsNow, object: nil)
                aiResult = "Popup stripping activated — cookie banners, overlays, and modals will be removed."
            }

            isProcessing = false
        }
    }

    private var unavailableMessage: String {
        switch aiClient.availability {
        case .available:
            return "Apple Intelligence is available."
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This Mac is not eligible for Apple Intelligence, so on-device page AI is unavailable."
            case .appleIntelligenceNotEnabled:
                return "Turn on Apple Intelligence in macOS settings to enable summaries, translation, and simplification."
            case .modelNotReady:
                return "Apple Intelligence is still preparing the on-device model. Try again in a moment."
            @unknown default:
                return "Apple Intelligence is currently unavailable on this Mac."
            }
        }
    }
}

struct AIToolButton: View {
    let title: String
    let icon: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .foregroundColor(BestBrowserBrand.secondary)
                        .neonGlow(BestBrowserBrand.secondary, radius: 2)
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.cardBackground)
            .foregroundColor(BestBrowserBrand.primary)
            .cornerRadius(6)
            .border(BestBrowserBrand.border, width: 0.5)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .help(title)
    }
}

// MARK: - History Panel

struct HistorySidebarView: View {
    @Binding var entries: [HistoryEntry]
    let storage: StorageManager

    @State private var searchText = ""

    var filteredEntries: [HistoryEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.title.lowercased().contains(searchText.lowercased()) ||
            entry.url.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search box
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(BestBrowserBrand.border)

                TextField("Filter history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.caption)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(BestBrowserBrand.border)
                    }
                    .buttonStyle(.plain)
                }

                if !entries.isEmpty {
                    Button(action: {
                        Task {
                            try? await storage.clearHistory()
                            entries = []
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(BestBrowserBrand.error)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .padding(8)

            // History list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredEntries) { entry in
                        HistoryItemView(entry: entry, onDelete: {
                            guard let id = entry.id else { return }
                            Task {
                                try? await storage.deleteHistoryEntry(id: id)
                                entries.removeAll { $0.id == id }
                            }
                        })
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .border(BestBrowserBrand.border, width: 0.5)
                    }
                }
            }
        }
    }
}

struct HistoryItemView: View {
    let entry: HistoryEntry
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title.isEmpty ? "No title" : entry.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(BestBrowserBrand.primary)

                Text(entry.url)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(BestBrowserBrand.border)

                HStack(spacing: 8) {
                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text("•")
                        .foregroundColor(.gray)

                    Text("\(entry.visitCount)x")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(BestBrowserBrand.error)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            BrowserViewModel.shared.openInCurrentTab(entry.url)
        }
    }
}

// MARK: - Bookmarks Panel

struct BookmarksSidebarView: View {
    @Binding var bookmarks: [Bookmark]
    let storage: StorageManager

    @State private var folders: Set<String> = []
    @State private var selectedFolder: String?

    var filteredBookmarks: [Bookmark] {
        if let folder = selectedFolder {
            return bookmarks.filter { $0.folder == folder }
        }
        return bookmarks
    }

    var body: some View {
        VStack(spacing: 0) {
            // Add bookmark button
            Button(action: {
                Task {
                    try? await BrowserViewModel.shared.addCurrentPageToBookmarks()
                    if let updatedBookmarks = try? await storage.getBookmarks() {
                        await MainActor.run {
                            bookmarks = updatedBookmarks
                            folders = Set(updatedBookmarks.map(\.folder))
                        }
                    }
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(BestBrowserBrand.primary)
                    Text("Add Bookmark")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
            }
            .buttonStyle(.plain)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .padding(8)

            ScrollView {
                VStack(spacing: 8) {
                    // Folders
                    if !folders.isEmpty {
                        VStack(spacing: 4) {
                            Text("FOLDERS")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(BestBrowserBrand.border)
                                .padding(.horizontal, 8)

                            ForEach(Array(folders).sorted(), id: \.self) { folder in
                                Button(action: {
                                    selectedFolder = selectedFolder == folder ? nil : folder
                                }) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .font(.caption)
                                        Text(folder)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(bookmarks.filter { $0.folder == folder }.count)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(selectedFolder == folder ? BestBrowserBrand.cardBackground : Color.clear)
                                    .foregroundColor(BestBrowserBrand.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Bookmarks
                    if !filteredBookmarks.isEmpty {
                        VStack(spacing: 4) {
                            if folders.isEmpty {
                                Text("BOOKMARKS")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(BestBrowserBrand.border)
                                    .padding(.horizontal, 8)
                            }

                            ForEach(filteredBookmarks) { bookmark in
                                BookmarkItemView(bookmark: bookmark, onDelete: {
                                    guard let id = bookmark.id else { return }
                                    Task {
                                        try? await storage.deleteBookmark(id: id)
                                        bookmarks.removeAll { $0.id == id }
                                        folders = Set(bookmarks.map(\.folder))
                                    }
                                })
                                    .padding(6)
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
        .onAppear {
            folders = Set(bookmarks.map { $0.folder })
        }
    }
}

struct BookmarkItemView: View {
    let bookmark: Bookmark
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(BestBrowserBrand.primary)

                Text(bookmark.url)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(BestBrowserBrand.border)
            }

            Spacer()

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(BestBrowserBrand.error)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            BrowserViewModel.shared.openInCurrentTab(bookmark.url)
        }
    }
}

// MARK: - Search Panel

struct SearchSidebarView: View {
    @Binding var query: String
    @Binding var results: SmartSearchResults
    let search: SemanticSearch
    @Binding var isLoading: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(BestBrowserBrand.primary)

                TextField("Search pages & history...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .onSubmit {
                        performSearch()
                    }

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(8)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.primary, width: 1)
            .padding(8)

            // Results
            ScrollView {
                VStack(spacing: 12) {
                    // Suggestions
                    if !results.suggestions.isEmpty && query.count < 3 {
                        VStack(spacing: 4) {
                            Text("SUGGESTIONS")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(BestBrowserBrand.border)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(results.suggestions) { suggestion in
                                Button(action: { query = suggestion.text; performSearch() }) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(BestBrowserBrand.secondary)
                                        Text(suggestion.text)
                                            .font(.caption)
                                        Spacer()
                                    }
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(BestBrowserBrand.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // History results
                    if !results.history.isEmpty {
                        VStack(spacing: 4) {
                            Text("HISTORY")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(BestBrowserBrand.border)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(results.history.prefix(5)) { entry in
                                HistoryItemView(entry: entry)
                            }
                        }
                    }

                    if !results.memories.isEmpty {
                        VStack(spacing: 4) {
                            Text("MEMORY")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(BestBrowserBrand.border)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(results.memories.prefix(5)) { memory in
                                MemoryItemView(memory: memory)
                            }
                        }
                    }

                    // Page results
                    if !results.pages.isEmpty {
                        VStack(spacing: 4) {
                            Text("PAGES")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(BestBrowserBrand.border)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(results.pages.prefix(5)) { page in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(page.title)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .foregroundColor(BestBrowserBrand.primary)

                                    Text(page.url)
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .foregroundColor(BestBrowserBrand.border)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    BrowserViewModel.shared.openInCurrentTab(page.url)
                                }
                            }
                        }
                    }

                    if query.isEmpty {
                        Text("Start typing to search...")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(16)
                    } else if results.totalResults == 0 && !isLoading {
                        Text("No results found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(16)
                    }
                }
                .padding(8)
            }
        }
    }

    private func performSearch() {
        guard !query.isEmpty else { return }
        isLoading = true

        Task {
            do {
                results = try await search.smartSearch(query)
            } catch {
                print("Search error: \(error)")
            }
            isLoading = false
        }
    }
}

struct MemoryItemView: View {
    let memory: PageMemory
    @StateObject private var pageMemoryService = PageMemoryService.shared
    @State private var isEditingNote = false
    @State private var noteDraft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(memory.title ?? memory.url)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(BestBrowserBrand.primary)

                if memory.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundColor(BestBrowserBrand.secondary)
                }

                Spacer()

                Button(action: {
                    Task { await pageMemoryService.togglePinned(memory) }
                }) {
                    Image(systemName: memory.isPinned ? "pin.slash" : "pin")
                        .foregroundColor(BestBrowserBrand.secondary)
                }
                .buttonStyle(.plain)

                Button(action: {
                    noteDraft = memory.note ?? ""
                    isEditingNote.toggle()
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(BestBrowserBrand.border)
                }
                .buttonStyle(.plain)
            }

            if let takeaway = memory.takeaway, !takeaway.isEmpty {
                Text(takeaway)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            } else if let summary = memory.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }

            Text(memory.url)
                .font(.caption2)
                .lineLimit(1)
                .foregroundColor(BestBrowserBrand.border)

            if let note = memory.note, !note.isEmpty, !isEditingNote {
                Text(note)
                    .font(.caption2)
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.9))
                    .lineLimit(3)
                    .padding(.top, 2)
            }

            if isEditingNote {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Add a note or takeaway…", text: $noteDraft, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)

                    HStack {
                        Button("Save") {
                            Task {
                                await pageMemoryService.updateNote(for: memory, note: noteDraft)
                                isEditingNote = false
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.caption2)
                        .foregroundColor(BestBrowserBrand.primary)

                        Button("Cancel") {
                            isEditingNote = false
                        }
                        .buttonStyle(.plain)
                        .font(.caption2)
                        .foregroundColor(BestBrowserBrand.border)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            BrowserViewModel.shared.openInCurrentTab(memory.url)
        }
    }
}

#Preview {
    BrowserInspectorView()
}
