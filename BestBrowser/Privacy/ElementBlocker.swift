import Foundation
import WebKit

@MainActor
class ElementBlocker: NSObject, ObservableObject {
    static let shared = ElementBlocker()

    @Published var blockedElements = 0
    @Published var blockedPopups = 0
    @Published var isEnabled = true

    let privacyShield = PrivacyShield.shared

    override init() {
        super.init()
        loadSettings()
    }

    private func loadSettings() {
        isEnabled = UserDefaults.standard.object(forKey: "elementBlockerEnabled") as? Bool ?? true
    }

    func injectBlockingScript(into webView: WKWebView) {
        guard isEnabled else { return }
        guard shouldInjectCleanupScript(for: webView.url) else { return }

        let script = """
        (function() {
            const adSelectors = [
                '.ad-banner',
                '.ad-slot',
                '.ad-unit',
                '.commercial-unit',
                '.adsbygoogle',
                '[data-ad-client]',
                '[data-ad-slot]',
                '[aria-label="advertisement"]',
                '[id^="google_ads_"]',
                '[id^="div-gpt-ad"]',
                'iframe[src*="doubleclick"]',
                'iframe[src*="googlesyndication"]',
                'iframe[src*="amazon-adsystem"]',
                'iframe[src*="adservice.google"]',
                'ins.adsbygoogle'
            ];

            let removed = 0;
            adSelectors.forEach(selector => {
                try {
                    document.querySelectorAll(selector).forEach(el => {
                        el.remove();
                        removed++;
                    });
                } catch(e) {}
            });

            return removed;
        })();
        """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func shouldInjectCleanupScript(for url: URL?) -> Bool {
        guard let host = url?.host?.lowercased() else { return true }

        let appLikeDomains = [
            "youtube.com", "www.youtube.com",
            "mail.google.com", "docs.google.com",
            "drive.google.com", "calendar.google.com",
            "app.slack.com", "discord.com",
            "figma.com", "notion.so"
        ]

        return !appLikeDomains.contains(host)
    }

    func blockPopup() {
        blockedPopups += 1
        privacyShield.recordBlockedResource(type: "popup")
    }

    func blockElement(_ selector: String, reason: String = "ad") {
        blockedElements += 1
        privacyShield.recordBlockedResource(type: reason)
    }

    func analyzePageStructure(title: String, url: String) -> PageAnalysis {
        let adUrlPatterns = ["/ads/", "/advert/", "/adserver/", "/ad-banner/", "doubleclick", "googlesyndication"]
        let trackerUrlPatterns = ["analytics", "tracking", "pixel", "beacon", "telemetry"]

        let urlLower = url.lowercased()
        let hasAds = adUrlPatterns.contains { urlLower.contains($0) }
        let hasTrackers = trackerUrlPatterns.contains { urlLower.contains($0) }
        let isNewsSite = urlLower.contains("news") || urlLower.contains("article")
        let isShoppingSite = urlLower.contains("shop") || urlLower.contains("store")

        var estimatedAds = 0
        if hasAds { estimatedAds += 5 }
        if isNewsSite { estimatedAds += 3 }
        if isShoppingSite { estimatedAds += 2 }

        let estimatedTrackers = hasTrackers ? 3 : 0

        return PageAnalysis(
            hasAds: hasAds || isNewsSite,
            estimatedAdCount: estimatedAds,
            estimatedTrackerCount: estimatedTrackers,
            recommendedBlockLevel: (estimatedAds + estimatedTrackers) > 5 ? .aggressive : .standard
        )
    }

    func toggle() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: "elementBlockerEnabled")
    }

    func reset() {
        blockedElements = 0
        blockedPopups = 0
    }
}

struct PageAnalysis {
    let hasAds: Bool
    let estimatedAdCount: Int
    let estimatedTrackerCount: Int
    let recommendedBlockLevel: BlockLevel

    enum BlockLevel {
        case gentle
        case standard
        case aggressive
    }
}
