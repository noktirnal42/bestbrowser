import Foundation
import WebKit

@MainActor
final class BrowserPageContextService {
    static let shared = BrowserPageContextService()

    private init() {}

    func textContent(from webView: WKWebView) async -> String? {
        guard webView.url != nil else { return nil }

        return await withCheckedContinuation { continuation in
            webView.evaluateJavaScript("document.body.innerText") { result, _ in
                continuation.resume(returning: result as? String)
            }
        }
    }

    func comparedContexts(
        from tabs: [BrowserTab],
        webViews: [UUID: WKWebView],
        newTabURL: String,
        limit: Int
    ) async -> [ComparedTabContext] {
        var contexts: [ComparedTabContext] = []

        for tab in tabs where tab.url != newTabURL {
            if contexts.count >= limit { break }
            let content = if let webView = webViews[tab.id] {
                await textContent(from: webView) ?? ""
            } else {
                ""
            }
            contexts.append(
                ComparedTabContext(
                    title: tab.title.isEmpty ? tab.url : tab.title,
                    url: tab.url,
                    content: String(content.prefix(2500))
                )
            )
        }

        return contexts
    }

    func detectFaviconURL(pageURL: URL?, in webView: WKWebView) async -> String? {
        guard let pageURL else { return nil }

        let detected = await withCheckedContinuation { continuation in
            webView.evaluateJavaScript("""
            (function() {
                const icon = document.querySelector('link[rel~="icon"]') ||
                             document.querySelector('link[rel="apple-touch-icon"]');
                return icon ? icon.href : null;
            })();
            """) { result, _ in
                continuation.resume(returning: result as? String)
            }
        }

        if let detected, !detected.isEmpty {
            return detected
        }

        guard let host = pageURL.host else { return nil }
        let scheme = pageURL.scheme ?? "https"
        return "\(scheme)://\(host)/favicon.ico"
    }

    func shouldUseYouTubeFocusedLiveFallback(
        in webView: WKWebView,
        siteCompatibility: SiteCompatibilityService
    ) async -> Bool {
        guard let currentURL = webView.url?.absoluteString.lowercased(),
              currentURL.contains("youtube.com/watch") else { return false }

        let payload = await withCheckedContinuation { continuation in
            webView.evaluateJavaScript("""
            (function() {
                const text = document.body ? (document.body.innerText || "") : "";
                const liveBadge = !!document.querySelector('.ytp-live-badge, ytd-badge-supported-renderer[icon-type="LIVE"]');
                const chatContainer = !!document.querySelector('ytd-live-chat-frame, iframe[src*="live_chat"], #chat, #chat-container');
                return JSON.stringify({
                    text,
                    liveBadge,
                    chatContainer
                });
            })();
            """) { result, _ in
                continuation.resume(returning: result as? String ?? "")
            }
        }

        let data = Data(payload.utf8)
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        let context = LiveFallbackContext(
            isLiveBadgeVisible: json["liveBadge"] as? Bool ?? false,
            hasChatContainer: json["chatContainer"] as? Bool ?? false,
            bodyText: json["text"] as? String ?? ""
        )

        return siteCompatibility.shouldUseFocusedLiveFallback(context)
    }
}
