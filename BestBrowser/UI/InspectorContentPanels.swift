import SwiftUI

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

struct SearchSidebarView: View {
    @Binding var query: String
    @Binding var results: SmartSearchResults
    let search: SemanticSearch
    @Binding var isLoading: Bool

    var body: some View {
        VStack(spacing: 0) {
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

            ScrollView {
                VStack(spacing: 12) {
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
