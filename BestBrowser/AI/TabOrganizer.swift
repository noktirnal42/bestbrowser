import Foundation

@MainActor
class TabOrganizer: NSObject, ObservableObject {
    static let shared = TabOrganizer()

    @Published var categories: [TabCategory] = TabCategory.allCategories
    @Published var suggestions: [TabGroupSuggestion] = []

    let aiClient = AIClient.shared

    override init() {
        super.init()
    }

    // MARK: - Tab Analysis

    func analyzeTab(title: String, url: String) async -> TabAnalysis {
        if let aiAnalysis = try? await aiAnalyzeTab(title: title, url: url) {
            return aiAnalysis
        }

        let category = categorizeTab(title: title, url: url)
        return TabAnalysis(
            title: title,
            url: url,
            category: category,
            suggestedGroup: suggestGroup(for: category)
        )
    }

    private func aiAnalyzeTab(title: String, url: String) async throws -> TabAnalysis {
        let prompt = """
        Categorize this browser tab into exactly one category from this list:
        social, communication, development, work, entertainment, shopping, news, research, other.

        Then suggest a short group name of 2 to 4 words.

        Return exactly two lines in this format:
        category: <category>
        group: <group name>

        Title: \(title)
        URL: \(url)
        """

        let response = try await aiClient.chat([["role": "user", "content": prompt]], maxTokens: 120, temperature: 0.2)
        let parsedCategory = parseValue(from: response, key: "category")
        let parsedGroup = parseValue(from: response, key: "group")
        let category = TabCategory(rawValue: parsedCategory.lowercased()) ?? categorizeTab(title: title, url: url)
        let groupName = parsedGroup.isEmpty ? suggestGroup(for: category) : parsedGroup

        return TabAnalysis(title: title, url: url, category: category, suggestedGroup: groupName)
    }

    private func categorizeTab(title: String, url: String) -> TabCategory {
        let combined = "\(title) \(url)".lowercased()

        // Social
        if combined.contains("facebook") || combined.contains("twitter") ||
           combined.contains("instagram") || combined.contains("reddit") ||
           combined.contains("linkedin") {
            return .social
        }

        // Communication
        if combined.contains("gmail") || combined.contains("slack") ||
           combined.contains("discord") || combined.contains("telegram") {
            return .communication
        }

        // Development
        if combined.contains("github") || combined.contains("stackoverflow") ||
           combined.contains("npm") || combined.contains("dev") ||
           combined.contains("docs") {
            return .development
        }

        // Work
        if combined.contains("google docs") || combined.contains("notion") ||
           combined.contains("trello") || combined.contains("jira") ||
           combined.contains("drive") {
            return .work
        }

        // Entertainment
        if combined.contains("youtube") || combined.contains("netflix") ||
           combined.contains("spotify") || combined.contains("twitch") {
            return .entertainment
        }

        // Shopping
        if combined.contains("amazon") || combined.contains("ebay") ||
           combined.contains("shop") || combined.contains("store") {
            return .shopping
        }

        // News
        if combined.contains("news") || combined.contains("medium") ||
           combined.contains("blog") {
            return .news
        }

        // Research
        if combined.contains("wikipedia") || combined.contains("edu") ||
           combined.contains("learn") {
            return .research
        }

        return .other
    }

    private func suggestGroup(for category: TabCategory) -> String {
        switch category {
        case .social: return "Social Media"
        case .communication: return "Communication"
        case .development: return "Development"
        case .work: return "Work"
        case .entertainment: return "Entertainment"
        case .shopping: return "Shopping"
        case .news: return "News & Reading"
        case .research: return "Research"
        case .other: return "Other"
        }
    }

    // MARK: - Grouping

    func generateSuggestions(for tabs: [(title: String, url: String)]) async {
        if let aiSuggestions = try? await aiGroupSuggestions(for: tabs), !aiSuggestions.isEmpty {
            suggestions = aiSuggestions
            return
        }

        var groups: [String: [String]] = [:]

        for (title, url) in tabs {
            let category = categorizeTab(title: title, url: url)
            let groupName = suggestGroup(for: category)

            if groups[groupName] == nil {
                groups[groupName] = []
            }
            groups[groupName]?.append(title)
        }

        suggestions = groups.map { groupName, titles in
            TabGroupSuggestion(
                groupName: groupName,
                tabTitles: titles,
                tabCount: titles.count
            )
        }
    }

    private func aiGroupSuggestions(for tabs: [(title: String, url: String)]) async throws -> [TabGroupSuggestion] {
        guard !tabs.isEmpty else { return [] }

        let tabList = tabs.enumerated().map { index, tab in
            "\(index + 1). \(tab.title) | \(tab.url)"
        }.joined(separator: "\n")

        let prompt = """
        Group these browser tabs into practical workspaces for a person browsing the web.
        Use short group names.
        Return one group per line using this format:
        Group Name: tab 1, tab 2

        Tabs:
        \(tabList)
        """

        let response = try await aiClient.chat([["role": "user", "content": prompt]], maxTokens: 220, temperature: 0.3)
        let parsed = parseGroupSuggestions(response, availableTitles: tabs.map(\.title))
        return parsed.isEmpty ? [] : parsed
    }

    // MARK: - Hibernation

    func suggestHibernation(for tabs: [(title: String, url: String)]) -> [String] {
        // Simple heuristic: suggest non-critical tabs
        return tabs.filter { title, _ in
            let combined = "\(title)".lowercased()
            return !combined.contains("work") &&
                   !combined.contains("email") &&
                   !combined.contains("slack") &&
                   !combined.contains("development")
        }.map { $0.title }
    }

    private func parseValue(from text: String, key: String) -> String {
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2, parts[0].lowercased() == key {
                return parts[1]
            }
        }
        return ""
    }

    private func parseGroupSuggestions(_ text: String, availableTitles: [String]) -> [TabGroupSuggestion] {
        text.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count == 2 else { return nil }
            let matchedTitles = availableTitles.filter { title in
                parts[1].localizedCaseInsensitiveContains(title)
            }
            guard !matchedTitles.isEmpty else { return nil }
            return TabGroupSuggestion(groupName: parts[0], tabTitles: matchedTitles, tabCount: matchedTitles.count)
        }
    }
}

// MARK: - Models

enum TabCategory: String, CaseIterable {
    case social
    case communication
    case development
    case work
    case entertainment
    case shopping
    case news
    case research
    case other

    var icon: String {
        switch self {
        case .social: return "person.2.fill"
        case .communication: return "message.fill"
        case .development: return "chevron.left.slash.chevron.right"
        case .work: return "briefcase.fill"
        case .entertainment: return "film.fill"
        case .shopping: return "bag.fill"
        case .news: return "newspaper.fill"
        case .research: return "book.fill"
        case .other: return "globe"
        }
    }

    var color: String {
        switch self {
        case .social: return "blue"
        case .communication: return "green"
        case .development: return "orange"
        case .work: return "red"
        case .entertainment: return "purple"
        case .shopping: return "pink"
        case .news: return "yellow"
        case .research: return "cyan"
        case .other: return "gray"
        }
    }

    static let allCategories = TabCategory.allCases
}

struct TabAnalysis {
    let title: String
    let url: String
    let category: TabCategory
    let suggestedGroup: String
}

struct TabGroupSuggestion: Identifiable {
    let id = UUID()
    let groupName: String
    let tabTitles: [String]
    let tabCount: Int
}
