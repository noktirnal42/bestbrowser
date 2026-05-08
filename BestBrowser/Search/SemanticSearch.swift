import Foundation

@MainActor
class SemanticSearch: NSObject, ObservableObject {
    static let shared = SemanticSearch()

    @Published var indexSize = 0
    @Published var isIndexing = false

    let storage = StorageManager.shared
    let aiClient = AIClient.shared

    override init() {
        super.init()
    }

    // MARK: - Indexing

    func indexPage(title: String, content: String, url: String) async throws {
        guard !content.isEmpty else { return }

        isIndexing = true
        defer { isIndexing = false }

        // Truncate content for indexing (first 5000 chars)
        let truncatedContent = String(content.prefix(5000))

        try await storage.indexSearch(
            title: title,
            content: truncatedContent,
            url: url,
            sourceId: Int64(url.hashValue),
            sourceType: "page"
        )

        indexSize += 1
    }

    func indexHistory(_ history: [HistoryEntry]) async throws {
        for entry in history {
            try await storage.indexSearch(
                title: entry.title,
                content: entry.url,
                url: entry.url,
                sourceId: entry.id ?? 0,
                sourceType: "history"
            )
        }
    }

    // MARK: - Searching

    func search(_ query: String, limit: Int = 50) async throws -> SearchResults {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return SearchResults(indexResults: [], historyResults: [], memoryResults: []) }

        return try await storage.searchAll(trimmedQuery, limit: limit)
    }

    func searchHistory(_ query: String) async throws -> [HistoryEntry] {
        return try await storage.searchHistory(query)
    }

    // MARK: - Smart Search

    func smartSearch(_ query: String) async throws -> SmartSearchResults {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else {
            return SmartSearchResults(pages: [], history: [], memories: [], suggestions: [])
        }

        let results = try await search(trimmedQuery)
        let suggestions = await generateSuggestions(from: results, query: trimmedQuery)

        return SmartSearchResults(
            pages: results.indexResults,
            history: results.historyResults,
            memories: results.memoryResults,
            suggestions: suggestions
        )
    }

    private func generateSuggestions(from results: SearchResults, query: String) async -> [SearchSuggestion] {
        if let aiSuggestions = try? await aiSuggestions(from: results, query: query), !aiSuggestions.isEmpty {
            return aiSuggestions
        }

        var suggestions: [SearchSuggestion] = []

        // Extract keywords from top results
        let topResults = results.indexResults.prefix(3)
        var keywords = Set<String>()

        for result in topResults {
            let words = result.title.split(separator: " ").map(String.init)
            keywords.formUnion(words.filter { $0.count > 3 })
        }

        // Create suggestions
        for keyword in keywords.prefix(5) {
            suggestions.append(SearchSuggestion(text: keyword, type: "keyword"))
        }

        return suggestions
    }

    private func aiSuggestions(from results: SearchResults, query: String) async throws -> [SearchSuggestion] {
        let pageContext = results.indexResults.prefix(3).map { "\($0.title) | \($0.url)" }
        let memoryContext = results.memoryResults.prefix(3).map { "\($0.title ?? $0.url) | \($0.takeaway ?? $0.summary ?? "")" }
        let context = (pageContext + memoryContext).joined(separator: "\n")
        guard !context.isEmpty else { return [] }

        let prompt = """
        A browser user searched for: \(query)

        Based on these matching pages, suggest up to four short follow-up searches.
        Return one suggestion per line with no numbering.

        Matches:
        \(context)
        """

        let response = try await aiClient.chat([["role": "user", "content": prompt]], maxTokens: 100, temperature: 0.4)
        return response
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(4)
            .map { SearchSuggestion(text: $0, type: "ai") }
    }

    func clearIndex() async throws {
        try await storage.clearSearchIndex()
        indexSize = 0
    }

    func getStats() -> SearchStats {
        SearchStats(indexSize: indexSize)
    }
}

// MARK: - Models

struct SmartSearchResults {
    let pages: [SearchIndexEntry]
    let history: [HistoryEntry]
    let memories: [PageMemory]
    let suggestions: [SearchSuggestion]

    var hasResults: Bool {
        !pages.isEmpty || !history.isEmpty || !memories.isEmpty
    }

    var totalResults: Int {
        pages.count + history.count + memories.count
    }
}

struct SearchSuggestion: Identifiable {
    let id = UUID()
    let text: String
    let type: String // "keyword", "history", "bookmark"
}

struct SearchStats {
    let indexSize: Int
}
