import Foundation

@MainActor
final class PageMemoryService: ObservableObject {
    static let shared = PageMemoryService()

    @Published private(set) var recentMemories: [PageMemory] = []

    private let storage = StorageManager.shared
    private let aiClient = AIClient.shared

    private init() {
        Task { await refreshRecent() }
    }

    func refreshRecent() async {
        recentMemories = (try? await storage.getPageMemories(limit: 20)) ?? []
    }

    func capturePage(title: String, url: String, content: String) async {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty, !trimmedContent.isEmpty else { return }

        let normalizedUrl = normalizeURL(url)
        let host = URL(string: url)?.host()
        let truncated = String(trimmedContent.prefix(6000))

        let analysis = await analyze(title: title, url: url, content: truncated)

        let memory = PageMemory(
            url: url,
            normalizedUrl: normalizedUrl,
            title: title.isEmpty ? url : title,
            host: host,
            summary: analysis.summary,
            takeaway: analysis.takeaway,
            keywords: analysis.keywords.joined(separator: ", "),
            lastVisitedAt: Date(),
            visitCount: 1
        )

        do {
            try await storage.upsertPageMemory(memory)
            await refreshRecent()
        } catch {
            print("Failed to store page memory: \(error)")
        }
    }

    func togglePinned(_ memory: PageMemory) async {
        guard let id = memory.id else { return }
        do {
            try await storage.updatePageMemory(id: id, note: memory.note, isPinned: !memory.isPinned)
            await refreshRecent()
        } catch {
            print("Failed to pin memory: \(error)")
        }
    }

    func updateNote(for memory: PageMemory, note: String) async {
        guard let id = memory.id else { return }
        do {
            let normalized = note.trimmingCharacters(in: .whitespacesAndNewlines)
            try await storage.updatePageMemory(
                id: id,
                note: normalized.isEmpty ? nil : normalized,
                isPinned: memory.isPinned
            )
            await refreshRecent()
        } catch {
            print("Failed to update memory note: \(error)")
        }
    }

    private func analyze(title: String, url: String, content: String) async -> (summary: String, takeaway: String, keywords: [String]) {
        if aiClient.isAvailable,
           let aiAnalysis = try? await aiAnalyze(title: title, url: url, content: content) {
            return aiAnalysis
        }

        let summary = heuristicSummary(from: content)
        let keywords = heuristicKeywords(from: "\(title) \(content)")
        let takeaway = keywords.isEmpty ? summary : "Key themes: \(keywords.prefix(4).joined(separator: ", "))"
        return (summary, takeaway, Array(keywords.prefix(6)))
    }

    private func aiAnalyze(title: String, url: String, content: String) async throws -> (summary: String, takeaway: String, keywords: [String]) {
        let prompt = """
        Analyze this web page for a browser memory system.
        Return exactly this format:
        summary: <1 concise sentence>
        takeaway: <1 practical sentence>
        keywords: <comma-separated keywords>

        Title: \(title)
        URL: \(url)
        Content:
        \(content)
        """

        let response = try await aiClient.chat([["role": "user", "content": prompt]], maxTokens: 220, temperature: 0.3)
        let summary = parseValue(in: response, key: "summary")
        let takeaway = parseValue(in: response, key: "takeaway")
        let keywords = parseValue(in: response, key: "keywords")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return (
            summary.isEmpty ? heuristicSummary(from: content) : summary,
            takeaway.isEmpty ? heuristicSummary(from: content) : takeaway,
            keywords.isEmpty ? Array(heuristicKeywords(from: content).prefix(6)) : keywords
        )
    }

    private func normalizeURL(_ raw: String) -> String {
        guard var components = URLComponents(string: raw) else { return raw }
        components.fragment = nil
        return components.url?.absoluteString ?? raw
    }

    private func heuristicSummary(from content: String) -> String {
        let sentences = content
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 30 }

        if let first = sentences.first {
            return first + "."
        }

        return String(content.prefix(180))
    }

    private func heuristicKeywords(from text: String) -> [String] {
        let stopWords: Set<String> = [
            "this", "that", "with", "from", "have", "your", "about", "https", "http",
            "there", "their", "they", "them", "page", "will", "would", "could", "should"
        ]

        let counts = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 4 && !stopWords.contains($0) }
            .reduce(into: [String: Int]()) { result, word in
                result[word, default: 0] += 1
            }

        return counts
            .sorted { $0.value > $1.value }
            .map(\.key)
    }

    private func parseValue(in text: String, key: String) -> String {
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2, parts[0].lowercased() == key {
                return parts[1]
            }
        }
        return ""
    }
}
