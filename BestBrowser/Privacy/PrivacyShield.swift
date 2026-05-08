import Foundation
import WebKit

@MainActor
class PrivacyShield: NSObject, ObservableObject {
    static let shared = PrivacyShield()

    @Published var isEnabled = true
    @Published var adBlockingEnabled = true
    @Published var trackerBlockingEnabled = true
    @Published var statsEnabled = true

    @Published var stats = PrivacyStats()

    private var contentRuleList: WKContentRuleList?
    private var attachedWebViews: WeakSet<WKWebView> = WeakSet()
    private var forcedProtectionWebViews: WeakSet<WKWebView> = WeakSet()
    private let exemptTopLevelDomains = [
        "mail.google.com",
        "docs.google.com",
        "drive.google.com",
        "calendar.google.com",
        "app.slack.com",
        "discord.com",
        "www.figma.com",
        "figma.com",
        "www.notion.so",
        "notion.so"
    ]

    override init() {
        super.init()
        loadSettings()
        setupContentBlocking()
    }

    private func loadSettings() {
        let userDefaults = UserDefaults.standard
        isEnabled = userDefaults.object(forKey: "privacyShieldEnabled") as? Bool ?? true
        adBlockingEnabled = userDefaults.object(forKey: "adBlockingEnabled") as? Bool ?? true
        trackerBlockingEnabled = userDefaults.object(forKey: "trackerBlockingEnabled") as? Bool ?? true
    }

    private func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "privacyShieldEnabled")
        UserDefaults.standard.set(adBlockingEnabled, forKey: "adBlockingEnabled")
        UserDefaults.standard.set(trackerBlockingEnabled, forKey: "trackerBlockingEnabled")
    }

    func setupContentBlocking() {
        let rules = buildContentRuleList()

        WKContentRuleListStore.default()?.compileContentRuleList(
            forIdentifier: "BestBrowserRules",
            encodedContentRuleList: rules,
            completionHandler: { [weak self] ruleList, error in
                if let error = error {
                    print("Content rule compilation failed: \(error)")
                    return
                }

                if let ruleList = ruleList {
                    DispatchQueue.main.async {
                        self?.contentRuleList = ruleList
                        self?.reapplyContentRules()
                    }
                }
            }
        )
    }

    private func buildContentRuleList() -> String {
        var rules: [[String: Any]] = []

        if adBlockingEnabled {
            rules.append(contentsOf: adBlockingRules())
        }

        if trackerBlockingEnabled {
            rules.append(contentsOf: trackerBlockingRules())
        }

        rules.append(contentsOf: fingerprintProtectionRules())

        let json = try? JSONSerialization.data(withJSONObject: rules, options: .prettyPrinted)
        return String(data: json ?? Data(), encoding: .utf8) ?? ""
    }

    private func adBlockingRules() -> [[String: Any]] {
        [
            contentRule(urlFilter: ".*\\/ads\\/.*", action: "block"),
            contentRule(urlFilter: ".*\\/ad-.*", action: "block"),
            contentRule(urlFilter: ".*adsystem\\..*", action: "block"),
            contentRule(urlFilter: ".*adsrv\\..*", action: "block"),
            contentRule(urlFilter: ".*adserver\\..*", action: "block"),
            contentRule(urlFilter: ".*googlesyndication\\..*", action: "block"),
            contentRule(urlFilter: ".*doubleclick\\.net.*", action: "block"),
            contentRule(urlFilter: ".*advert\\..*", action: "block"),
            contentRule(urlFilter: ".*banner\\..*", action: "block"),
            contentRule(urlFilter: ".*yandex\\.net\\/ads.*", action: "block"),
        ]
    }

    private func trackerBlockingRules() -> [[String: Any]] {
        [
            contentRule(urlFilter: ".*google-analytics\\..*", action: "block"),
            contentRule(urlFilter: ".*analytics\\.google\\..*", action: "block"),
            contentRule(urlFilter: ".*segment\\.com.*", action: "block"),
            contentRule(urlFilter: ".*mixpanel\\..*", action: "block"),
            contentRule(urlFilter: ".*newrelic\\..*", action: "block"),
            contentRule(urlFilter: ".*facebook\\.com\\/tr.*", action: "block"),
            contentRule(urlFilter: ".*facebook\\.com\\/rsrc.*", action: "block"),
            contentRule(urlFilter: ".*fbcdn\\.net.*", action: "block"),
            contentRule(urlFilter: ".*twitter\\.com\\/i\\/.*", action: "block"),
            contentRule(urlFilter: ".*bat\\.bing\\.com.*", action: "block"),
            contentRule(urlFilter: ".*linkedin\\.com\\/px.*", action: "block"),
            contentRule(urlFilter: ".*pinterest\\.com\\/ct\\.html.*", action: "block"),
        ]
    }

    private func fingerprintProtectionRules() -> [[String: Any]] {
        [
            contentRule(urlFilter: ".*fingerprint.*", action: "block"),
            contentRule(urlFilter: ".*entropy\\.js.*", action: "block"),
        ]
    }

    private func contentRule(urlFilter: String, action: String) -> [String: Any] {
        [
            "trigger": [
                "url-filter": urlFilter,
                "resource-type": ["script", "image", "style-sheet", "font", "fetch", "xhr"],
                "unless-domain": exemptTopLevelDomains
            ],
            "action": [
                "type": action,
            ],
        ]
    }

    func attachTo(_ webView: WKWebView, pageURL: URL? = nil, forceProtection: Bool = false) {
        if !attachedWebViews.contains(webView) {
            attachedWebViews.add(webView)
        }
        if forceProtection {
            if !forcedProtectionWebViews.contains(webView) {
                forcedProtectionWebViews.add(webView)
            }
        }

        if !forceProtection && shouldBypassProtection(for: pageURL ?? webView.url) {
            clearProtection(from: webView)
            return
        }

        applyProtection(to: webView)
    }

    private func reapplyContentRules() {
        for webView in attachedWebViews.allObjects() {
            let shouldForce = forcedProtectionWebViews.contains(webView)
            if !shouldForce && shouldBypassProtection(for: webView.url) {
                clearProtection(from: webView)
                continue
            }
            applyProtection(to: webView)
        }
    }

    private func applyProtection(to webView: WKWebView) {
        if let contentRuleList = contentRuleList {
            webView.configuration.userContentController.removeAllContentRuleLists()
            webView.configuration.userContentController.add(contentRuleList)
        }

        webView.configuration.userContentController.removeScriptMessageHandler(forName: "blockedResource")
        webView.configuration.userContentController.add(self, name: "blockedResource")
    }

    private func clearProtection(from webView: WKWebView) {
        webView.configuration.userContentController.removeAllContentRuleLists()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "blockedResource")
    }

    func shouldBypassProtection(for url: URL?) -> Bool {
        guard let host = url?.host?.lowercased() else { return false }
        let compatibilityModeEnabled = UserDefaults.standard.object(forKey: "siteCompatibilityMode") as? Bool ?? true
        guard compatibilityModeEnabled else { return false }
        return exemptTopLevelDomains.contains(host)
    }

    func recordBlockedResource(type: String) {
        stats.blockedCount += 1

        if type == "tracker" {
            stats.trackersBlocked += 1
        } else if type == "ad" {
            stats.adsBlocked += 1
        }

        stats.timeSaved = Double(stats.blockedCount) * 0.002
    }

    func toggle() {
        isEnabled.toggle()
        saveSettings()
    }

    func toggleAdBlocking() {
        adBlockingEnabled.toggle()
        saveSettings()
        setupContentBlocking()
    }

    func toggleTrackerBlocking() {
        trackerBlockingEnabled.toggle()
        saveSettings()
        setupContentBlocking()
    }

    func resetStats() {
        stats = PrivacyStats()
    }
}

// Weak set to track attached WebViews without preventing deallocation
final class WeakSet<T: AnyObject> {
    private var objects: [WeakRef<T>] = []

    func add(_ object: T) {
        objects.append(WeakRef(object))
        purge()
    }

    func contains(_ object: T) -> Bool {
        purge()
        return objects.contains { $0.object === object }
    }

    func allObjects() -> [T] {
        purge()
        return objects.compactMap(\.object)
    }

    private func purge() {
        objects.removeAll { $0.object == nil }
    }
}

final class WeakRef<T: AnyObject> {
    weak var object: T?
    init(_ object: T) { self.object = object }
}

extension PrivacyShield: WKScriptMessageHandler {
    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let messageName = message.name
            let messageBody = message.body

            guard messageName == "blockedResource",
                  let body = messageBody as? [String: String],
                  let type = body["type"] else { return }

            self.recordBlockedResource(type: type)
        }
    }
}

@MainActor
class PrivacyStats: ObservableObject {
    @Published var blockedCount = 0
    @Published var adsBlocked = 0
    @Published var trackersBlocked = 0
    @Published var timeSaved = 0.0

    func formattedTimeSaved() -> String {
        if timeSaved < 1 {
            return String(format: "%.0fms", timeSaved * 1000)
        } else if timeSaved < 60 {
            return String(format: "%.1fs", timeSaved)
        } else {
            let minutes = Int(timeSaved / 60)
            return "\(minutes)m"
        }
    }
}
