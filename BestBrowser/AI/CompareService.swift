import Foundation

@MainActor
final class CompareService: ObservableObject {
    static let shared = CompareService()

    @Published private(set) var recentSessions: [CompareSession] = []
    @Published var latestComparison: String?
    @Published var latestPresentation: ComparePresentation?
    @Published var isComparing = false

    private let storage = StorageManager.shared
    private let aiClient = AIClient.shared

    private init() {
        Task { await refresh() }
    }

    func refresh() async {
        recentSessions = (try? await storage.getCompareSessions(limit: 10)) ?? []
    }

    func compareOpenTabs() async -> ComparePresentation {
        let contexts = await BrowserViewModel.shared.openTabContexts(limit: 4)
        guard contexts.count >= 2 else {
            let message = "Open at least two loaded tabs to compare them."
            latestComparison = message
            let presentation = ComparePresentation(markdown: message, citations: [])
            latestPresentation = presentation
            return presentation
        }

        isComparing = true
        defer { isComparing = false }

        let comparison: String
        if aiClient.isAvailable, let result = try? await aiCompare(contexts) {
            comparison = result
        } else {
            comparison = heuristicCompare(contexts)
        }

        latestComparison = comparison
        let citations = contexts.enumerated().map { index, context in
            CompareCitation(
                index: index + 1,
                title: context.title,
                url: context.url,
                host: URL(string: context.url)?.host() ?? context.url
            )
        }
        let presentation = ComparePresentation(
            markdown: comparison,
            citations: citations
        )
        latestPresentation = presentation

        do {
            try await storage.addCompareSession(
                title: "Open Tab Comparison",
                workspaceId: nil,
                sourceUrls: contexts.map(\.url),
                resultMarkdown: comparison
            )
            await refresh()
        } catch {
            print("Failed to save compare session: \(error)")
        }

        return presentation
    }

    private func aiCompare(_ contexts: [ComparedTabContext]) async throws -> String {
        let payload = contexts.enumerated().map { index, context in
            """
            Source \(index + 1):
            Title: \(context.title)
            URL: \(context.url)
            Excerpt:
            \(String(context.content.prefix(1800)))
            """
        }.joined(separator: "\n\n")

        let prompt = """
        Compare these browser tabs for a user doing research.
        Return markdown with exactly these sections:
        ## Shared Themes
        ## Key Differences
        ## Best Sources For
        ## Suggested Next Step

        In each section, cite sources using [1], [2], etc. when you reference them.

        \(payload)
        """

        return try await aiClient.chat([["role": "user", "content": prompt]], maxTokens: 700, temperature: 0.35)
    }

    private func heuristicCompare(_ contexts: [ComparedTabContext]) -> String {
        let titles = contexts.map(\.title)
        let hosts = contexts.compactMap { URL(string: $0.url)?.host() }
        let hostSummary = Dictionary(grouping: hosts, by: { $0 }).mapValues(\.count)
            .sorted { $0.value > $1.value }
            .map { "\($0.key) (\($0.value))" }
            .joined(separator: ", ")

        return """
        ## Shared Themes
        These tabs appear to be part of the same research cluster: \(titles.prefix(3).joined(separator: ", ")) [1].

        ## Key Differences
        The strongest difference is source mix and emphasis across \(contexts.count) tabs. Hosts involved: \(hostSummary.isEmpty ? "mixed sources" : hostSummary) [1].

        ## Best Sources For
        Use the first tab for the lead reference, then cross-check the remaining tabs for supporting details and alternatives [1].

        ## Suggested Next Step
        Save this session as a workspace, then close duplicate tabs and keep the strongest 2-3 sources open.
        """
    }
}
