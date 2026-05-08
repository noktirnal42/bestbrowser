import Foundation
import WebKit

@MainActor
final class BrowserPageActionService {
    static let shared = BrowserPageActionService()

    private init() {}

    func cleanPage(in webView: WKWebView, privacyShield: PrivacyShield, blocker: ElementBlocker) {
        blocker.injectBlockingScript(into: webView)
        webView.evaluateJavaScript(Self.cleanPageScript) { result, _ in
            if let count = result as? Int, count > 0 {
                privacyShield.recordBlockedResource(type: "ad")
            }
        }
    }

    func stripPopups(in webView: WKWebView, privacyShield: PrivacyShield) {
        webView.evaluateJavaScript(Self.stripPopupsScript) { result, _ in
            if let count = result as? Int, count > 0 {
                privacyShield.recordBlockedResource(type: "popup")
            }
        }
    }

    func repairYouTubeLayout(for tabId: UUID, using viewModel: BrowserViewModel) {
        viewModel.enableYouTubeFocusedLiveMode(for: tabId)
    }

    private static let cleanPageScript = """
    (function() {
        const host = window.location.hostname;
        if ([
            'www.youtube.com', 'youtube.com', 'mail.google.com', 'docs.google.com',
            'drive.google.com', 'calendar.google.com', 'app.slack.com',
            'discord.com', 'www.figma.com', 'www.notion.so'
        ].includes(host)) {
            return 0;
        }
        let removed = 0;
        const selectors = [
            '.ad-banner', '.ad-slot', '.ad-unit', '.commercial-unit',
            '.adsbygoogle', '[data-ad-client]', '[data-ad-slot]',
            '[aria-label="advertisement"]', '[id^="google_ads_"]', '[id^="div-gpt-ad"]',
            'iframe[src*="doubleclick"]', 'iframe[src*="googlesyndication"]',
            'iframe[src*="adservice.google"]', 'ins.adsbygoogle',
            '[aria-modal="true"][data-nosnippet="true"]',
            '[id*="cookie-banner"]', '[class*="cookie-banner"]',
            '[data-testid*="cookie"]', '[class*="newsletter-popup"]',
            '[class*="paywall"]'
        ];
        selectors.forEach(sel => {
            try { document.querySelectorAll(sel).forEach(el => { el.remove(); removed++; }); } catch(e) {}
        });
        return removed;
    })();
    """

    private static let stripPopupsScript = """
    (function() {
        const host = window.location.hostname;
        if ([
            'www.youtube.com', 'youtube.com', 'mail.google.com', 'docs.google.com',
            'drive.google.com', 'calendar.google.com', 'app.slack.com',
            'discord.com', 'www.figma.com', 'www.notion.so'
        ].includes(host)) {
            return 0;
        }
        let removed = 0;
        document.querySelectorAll('[aria-modal="true"][data-nosnippet="true"], [class*="cookie-banner"], [id*="cookie"], [class*="consent-banner"], [id*="consent"]').forEach(el => {
            if (el.style) { el.style.display = 'none'; removed++; }
        });
        document.querySelectorAll('div[style*="fixed"], div[style*="sticky"]').forEach(el => {
            const text = (el.innerText || '').toLowerCase();
            const isConsentLike = text.includes('cookie') || text.includes('privacy') || text.includes('subscribe');
            if (isConsentLike && el.offsetHeight > window.innerHeight * 0.2) {
                el.remove();
                removed++;
            }
        });
        document.body.style.overflow = 'auto';
        return removed;
    })();
    """
}
