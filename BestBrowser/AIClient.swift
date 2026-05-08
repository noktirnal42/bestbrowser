import Foundation
import FoundationModels

enum AIError: LocalizedError {
    case modelUnavailable(String)
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let message):
            return message
        case .generationFailed(let message):
            return message
        }
    }
}

@MainActor
class AIClient: NSObject, ObservableObject {
    static let shared = AIClient()

    @Published private(set) var availability: SystemLanguageModel.Availability = .available
    @Published var isStreaming = false
    @Published var currentResponse = ""

    private let model = SystemLanguageModel.default

    var isAvailable: Bool {
        model.isAvailable
    }

    override init() {
        super.init()
        refreshAvailability()
    }

    func refreshAvailability() {
        availability = model.availability
    }

    func testConnection() async throws -> Bool {
        refreshAvailability()
        guard model.isAvailable else {
            throw AIError.modelUnavailable(unavailabilityMessage())
        }

        let session = makeSession(instructions: "You are a concise on-device assistant. Reply with one short confirmation.")
        let response = try await session.respond(
            to: "Reply with OK.",
            options: GenerationOptions(temperature: 0.2, maximumResponseTokens: 8)
        )
        return !response.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func chat(
        _ messages: [[String: String]],
        maxTokens: Int = 500,
        temperature: Double = 0.7
    ) async throws -> String {
        refreshAvailability()
        guard model.isAvailable else {
            throw AIError.modelUnavailable(unavailabilityMessage())
        }

        let session = makeSession(instructions: systemInstructions(from: messages))
        let prompt = promptText(from: messages)

        do {
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(temperature: temperature, maximumResponseTokens: maxTokens)
            )
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw mapError(error)
        }
    }

    func streamChat(
        _ messages: [[String: String]],
        maxTokens: Int = 1000,
        onChunk: @escaping (String) -> Void
    ) async throws {
        refreshAvailability()
        guard model.isAvailable else {
            throw AIError.modelUnavailable(unavailabilityMessage())
        }

        let session = makeSession(instructions: systemInstructions(from: messages))
        let prompt = promptText(from: messages)

        isStreaming = true
        currentResponse = ""
        defer { isStreaming = false }

        do {
            let stream = session.streamResponse(
                to: prompt,
                options: GenerationOptions(temperature: 0.6, maximumResponseTokens: maxTokens)
            )

            var streamedSoFar = ""
            for try await snapshot in stream {
                let fullText = snapshot.content
                guard fullText.count >= streamedSoFar.count else { continue }
                let delta = String(fullText.dropFirst(streamedSoFar.count))
                streamedSoFar = fullText
                currentResponse = fullText
                if !delta.isEmpty {
                    onChunk(delta)
                }
            }
        } catch {
            throw mapError(error)
        }
    }

    func summarize(_ text: String) async throws -> String {
        let messages: [[String: String]] = [
            ["role": "system", "content": "Summarize the text concisely in 2-3 sentences."],
            ["role": "user", "content": text]
        ]

        return try await chat(messages, maxTokens: 220, temperature: 0.4)
    }

    func generateTitle(_ content: String) async throws -> String {
        let messages: [[String: String]] = [
            ["role": "system", "content": "Generate a short title with at most five words. Return only the title."],
            ["role": "user", "content": content]
        ]

        return try await chat(messages, maxTokens: 24, temperature: 0.5)
    }

    private func makeSession(instructions: String) -> LanguageModelSession {
        LanguageModelSession(model: model, instructions: instructions)
    }

    private func systemInstructions(from messages: [[String: String]]) -> String {
        let systemMessages = messages
            .filter { $0["role"] == "system" }
            .compactMap { $0["content"] }

        if systemMessages.isEmpty {
            return "You are BestBrowser's on-device reading and browsing assistant. Be concise, factual, and helpful."
        }

        return systemMessages.joined(separator: "\n\n")
    }

    private func promptText(from messages: [[String: String]]) -> String {
        let conversationalMessages = messages.filter { $0["role"] != "system" }
        guard !conversationalMessages.isEmpty else { return "" }

        return conversationalMessages.map { message in
            let role = (message["role"] ?? "user").capitalized
            let content = message["content"] ?? ""
            return "\(role): \(content)"
        }
        .joined(separator: "\n\n")
    }

    private func unavailabilityMessage() -> String {
        switch availability {
        case .available:
            return "Apple Foundation Model is available."
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This Mac isn't eligible for Apple Intelligence, so on-device AI features aren't available."
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is turned off. Enable it in macOS settings to use BestBrowser AI features."
            case .modelNotReady:
                return "The Apple Foundation Model isn't ready yet. Try again after macOS finishes preparing Apple Intelligence."
            @unknown default:
                return "The Apple Foundation Model is currently unavailable on this Mac."
            }
        }
    }

    private func mapError(_ error: Error) -> AIError {
        if let generationError = error as? LanguageModelSession.GenerationError {
            return .generationFailed(generationError.errorDescription ?? generationError.localizedDescription)
        }

        return .generationFailed(error.localizedDescription)
    }
}
