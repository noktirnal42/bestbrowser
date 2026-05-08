import Foundation

struct LiveFallbackContext: Equatable {
    let isLiveBadgeVisible: Bool
    let hasChatContainer: Bool
    let bodyText: String
}

@MainActor
final class SiteCompatibilityService {
    static let shared = SiteCompatibilityService()

    private init() {}

    func isYouTubeWatchURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else { return false }

        let normalizedHost = host.replacingOccurrences(of: "www.", with: "")
        return normalizedHost == "youtube.com" && url.path == "/watch"
    }

    func youTubeVideoID(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString),
              let host = components.host?.lowercased() else { return nil }

        let normalizedHost = host.replacingOccurrences(of: "www.", with: "")
        if normalizedHost == "youtu.be" {
            let id = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }

        return components.queryItems?.first(where: { $0.name == "v" })?.value
    }

    func youTubeEmbedURL(for tab: BrowserTab) -> String? {
        guard isYouTubeWatchURL(tab.url),
              let videoId = youTubeVideoID(from: tab.url) else { return nil }

        let params = [
            "autoplay=1",
            "playsinline=1",
            "rel=0",
            "modestbranding=1"
        ].joined(separator: "&")

        return "https://www.youtube.com/embed/\(videoId)?\(params)"
    }

    func shouldUseFocusedLiveFallback(_ context: LiveFallbackContext) -> Bool {
        context.bodyText.contains("Please update it to use live chat")
        || (context.isLiveBadgeVisible && context.hasChatContainer)
    }
}

