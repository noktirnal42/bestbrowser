import Foundation

@MainActor
class ContentSummarizer: NSObject, ObservableObject {
    static let shared = ContentSummarizer()

    @Published var isSummarizing = false
    @Published var currentSummary = ""

    let aiClient = AIClient.shared

    override init() {
        super.init()
    }

    // MARK: - Summarization

    func summarize(
        _ text: String,
        style: SummaryStyle = .concise,
        onUpdate: ((String) -> Void)? = nil
    ) async throws -> String {
        guard !text.isEmpty else { return "" }

        isSummarizing = true
        defer { isSummarizing = false }

        // Truncate long content (max 10000 chars)
        let truncated = String(text.prefix(10000))

        let systemPrompt = systemMessage(for: style)
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": truncated],
        ]

        currentSummary = ""

        do {
            try await aiClient.streamChat(messages, maxTokens: 500) { chunk in
                Task { @MainActor in
                    self.currentSummary += chunk
                    onUpdate?(chunk)
                }
            }
        } catch {
            throw SummaryError.summarizationFailed(error.localizedDescription)
        }

        return currentSummary
    }

    func extractKeyPoints(_ text: String, count: Int = 5) async throws -> [String] {
        guard !text.isEmpty else { return [] }

        let truncated = String(text.prefix(5000))
        let prompt = "Extract the \(count) most important key points from this text as a numbered list:"

        let messages: [[String: String]] = [
            ["role": "user", "content": "\(prompt)\n\n\(truncated)"],
        ]

        let response = try await aiClient.chat(messages, maxTokens: 300)
        return parseKeyPoints(response)
    }

    func generateTableOfContents(_ text: String) async throws -> [TOCEntry] {
        guard !text.isEmpty else { return [] }

        let truncated = String(text.prefix(5000))
        let prompt = """
            Generate a table of contents for this text.
            Format each entry as "- [Level] Title"
            Where level is 1, 2, or 3
            """

        let messages: [[String: String]] = [
            ["role": "user", "content": "\(prompt)\n\n\(truncated)"],
        ]

        let response = try await aiClient.chat(messages, maxTokens: 400)
        return parseTOC(response)
    }

    // MARK: - Reading Metrics

    func getReadingTime(for text: String) -> ReadingMetrics {
        let wordCount = text.split(separator: " ").count
        let readingSpeed = 200 // words per minute
        let minutes = max(1, wordCount / readingSpeed)

        return ReadingMetrics(
            wordCount: wordCount,
            characterCount: text.count,
            estimatedMinutes: minutes
        )
    }

    // MARK: - Private Helpers

    private func systemMessage(for style: SummaryStyle) -> String {
        switch style {
        case .concise:
            return "Summarize the text in 2-3 sentences. Be concise and capture the main idea."
        case .detailed:
            return "Summarize the text in 4-5 sentences. Include important details and context."
        case .bullets:
            return "Summarize the text as 3-5 bullet points. Each point should be a complete thought."
        case .paragraph:
            return "Summarize the text in 1-2 paragraphs. Maintain a narrative structure."
        }
    }

    private func parseKeyPoints(_ response: String) -> [String] {
        return response
            .split(separator: "\n")
            .filter { !$0.isEmpty }
            .map { line in
                var cleaned = String(line)
                // Remove numbering
                if let range = cleaned.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
                    cleaned.removeSubrange(range)
                }
                // Remove bullets
                if let range = cleaned.range(of: "^[-•*]\\s*", options: .regularExpression) {
                    cleaned.removeSubrange(range)
                }
                return cleaned.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }

    private func parseTOC(_ response: String) -> [TOCEntry] {
        return response
            .split(separator: "\n")
            .compactMap { line in
                let trimmed = String(line).trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("-") || trimmed.hasPrefix("•") else { return nil }

                var title = trimmed
                if title.hasPrefix("-") {
                    title = String(title.dropFirst()).trimmingCharacters(in: .whitespaces)
                } else if title.hasPrefix("•") {
                    title = String(title.dropFirst()).trimmingCharacters(in: .whitespaces)
                }

                // Simple level detection based on spacing
                let level = 1 // Could be improved with indentation detection

                return TOCEntry(level: level, title: title)
            }
    }
}

// MARK: - Models

enum SummaryStyle: String, CaseIterable {
    case concise = "Concise"
    case detailed = "Detailed"
    case bullets = "Bullet Points"
    case paragraph = "Paragraph"
}

struct ReadingMetrics {
    let wordCount: Int
    let characterCount: Int
    let estimatedMinutes: Int

    var formattedTime: String {
        if estimatedMinutes < 1 {
            return "< 1 min"
        } else if estimatedMinutes == 1 {
            return "1 min"
        } else {
            return "\(estimatedMinutes) mins"
        }
    }
}

struct TOCEntry: Identifiable {
    let id = UUID()
    let level: Int
    let title: String

    var indent: CGFloat {
        CGFloat((level - 1) * 20)
    }
}

enum SummaryError: LocalizedError {
    case summarizationFailed(String)

    var errorDescription: String? {
        switch self {
        case .summarizationFailed(let msg):
            return "Summarization failed: \(msg)"
        }
    }
}
