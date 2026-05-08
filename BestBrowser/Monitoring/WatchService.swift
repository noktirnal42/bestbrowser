import CryptoKit
import AppKit
import Foundation
import UserNotifications

@MainActor
final class WatchService: ObservableObject {
    enum NotificationAccessState {
        case unknown
        case available
        case unavailable(String)
    }

    static let shared = WatchService()

    @Published private(set) var watchItems: [WatchStatusSummary] = []
    @Published var isChecking = false
    @Published var statusMessage: String?
    @Published private(set) var notificationAccessState: NotificationAccessState = .unknown

    private let storage = StorageManager.shared
    private let aiClient = AIClient.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private var monitorTimer: Timer?
    private let monitorInterval: TimeInterval = 15 * 60

    private init() {
        Task {
            await refresh()
            await requestNotificationAuthorization()
            await refreshNotificationSettings()
            startMonitoring()
        }
    }

    func refresh() async {
        do {
            let rules = try await storage.getWatchRules()
            var items: [WatchStatusSummary] = []
            for rule in rules {
                let snapshot = try await storage.getLatestWatchSnapshot(ruleId: rule.id ?? 0)
                items.append(WatchStatusSummary(id: rule.id ?? 0, rule: rule, latestSnapshot: snapshot))
            }
            watchItems = items
            statusMessage = nil
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func addCurrentPageWatch() async {
        guard let tab = BrowserViewModel.shared.currentTab,
              !BrowserViewModel.shared.isNewTab(tab),
              let content = await BrowserViewModel.shared.currentPageContent() else {
            statusMessage = "Open a real page before creating a watch."
            return
        }

        let summary = await summarize(content: String(content.prefix(4000)), title: tab.title, url: tab.url)

        do {
            let rule = try await storage.createWatchRule(
                url: tab.url,
                title: tab.title.isEmpty ? tab.url : tab.title,
                watchType: "page-change",
                prompt: "Watch this page for meaningful content changes."
            )
            try await storage.addWatchSnapshot(
                WatchSnapshot(
                    watchRuleId: rule.id ?? 0,
                    contentHash: hash(content),
                    summary: summary,
                    changeSummary: "Baseline snapshot created."
                )
            )
            await refresh()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func checkAll() async {
        isChecking = true
        defer { isChecking = false }

        for item in watchItems where item.rule.status == .active {
            await check(item.rule)
        }
        await refresh()
    }

    func check(_ rule: WatchRule) async {
        guard let ruleId = rule.id,
              let url = URL(string: rule.url) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(decoding: data, as: UTF8.self)
            let content = extractText(from: html)
            let contentHash = hash(content)
            let previous = try await storage.getLatestWatchSnapshot(ruleId: ruleId)

            guard previous?.contentHash != contentHash else {
                try await storage.updateWatchRuleCheck(id: ruleId, status: rule.status)
                return
            }

            let summary = await summarize(content: String(content.prefix(4000)), title: rule.title ?? rule.url, url: rule.url)
            let changeSummary = await changeSummary(
                oldSummary: previous?.summary ?? "",
                newSummary: summary,
                prompt: rule.prompt
            )

            try await storage.addWatchSnapshot(
                WatchSnapshot(
                    watchRuleId: ruleId,
                    contentHash: contentHash,
                    summary: summary,
                    changeSummary: changeSummary
                )
            )
            try await storage.updateWatchRuleCheck(id: ruleId, status: rule.status)
            await sendNotification(for: rule, changeSummary: changeSummary)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func toggle(_ item: WatchStatusSummary) async {
        guard let id = item.rule.id else { return }
        let nextStatus: WatchRule.Status = item.rule.status == .active ? .paused : .active
        do {
            try await storage.updateWatchRuleCheck(id: id, status: nextStatus)
            await refresh()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func delete(_ item: WatchStatusSummary) async {
        guard let id = item.rule.id else { return }
        do {
            try await storage.deleteWatchRule(id: id)
            await refresh()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func summarize(content: String, title: String, url: String) async -> String {
        if aiClient.isAvailable {
            let prompt = """
            Summarize this watched page in one concise sentence.
            Title: \(title)
            URL: \(url)
            Content:
            \(content)
            """
            if let result = try? await aiClient.chat([["role": "user", "content": prompt]], maxTokens: 100, temperature: 0.3) {
                return result
            }
        }
        return String(content.prefix(180))
    }

    private func changeSummary(oldSummary: String, newSummary: String, prompt: String?) async -> String {
        if aiClient.isAvailable {
            let request = """
            Compare the previous page summary to the new page summary and describe what changed in one or two sentences.
            Watch intent: \(prompt ?? "general page monitoring")
            Previous: \(oldSummary)
            New: \(newSummary)
            """
            if let result = try? await aiClient.chat([["role": "user", "content": request]], maxTokens: 140, temperature: 0.3) {
                return result
            }
        }

        if oldSummary.isEmpty {
            return "A new snapshot was captured for this page."
        }
        return oldSummary == newSummary ? "The page changed slightly, but the main summary looks similar." : "The page content changed enough to produce a different summary."
    }

    private func extractText(from html: String) -> String {
        let strippedScripts = html.replacingOccurrences(
            of: "<script[\\s\\S]*?</script>|<style[\\s\\S]*?</style>",
            with: " ",
            options: .regularExpression
        )
        let plainText = strippedScripts.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        return plainText
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "\\s+",
                                  with: " ",
                                  options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hash(_ content: String) -> String {
        let digest = SHA256.hash(data: Data(content.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func startMonitoring() {
        guard monitorTimer == nil else { return }

        monitorTimer = Timer.scheduledTimer(withTimeInterval: monitorInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAll()
            }
        }
        monitorTimer?.tolerance = 60
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func requestNotificationAuthorization() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            notificationAccessState = granted
                ? .available
                : .unavailable("Desktop alerts are off. Watchlist checks still work, but BestBrowser will not post notifications.")
        } catch {
            notificationAccessState = .unavailable("BestBrowser could not request notification access. Watchlist checks still work without alerts.")
        }
    }

    func refreshNotificationSettings() async {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            notificationAccessState = .available
        case .denied:
            notificationAccessState = .unavailable("Desktop alerts are blocked for BestBrowser. Watchlist checks still work, but notifications are turned off.")
        case .notDetermined:
            notificationAccessState = .unavailable("Desktop alerts have not been enabled yet. You can still use Watchlist without notifications.")
        @unknown default:
            notificationAccessState = .unavailable("BestBrowser could not confirm notification access. Watchlist checks still work.")
        }
    }

    func openNotificationsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }

    private func sendNotification(for rule: WatchRule, changeSummary: String) async {
        if case .unavailable = notificationAccessState {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = rule.title?.isEmpty == false ? rule.title! : "Watched Page Changed"
        content.body = changeSummary
        content.sound = .default
        content.userInfo = ["url": rule.url]

        let request = UNNotificationRequest(
            identifier: rule.uuid,
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            notificationAccessState = .unavailable("BestBrowser could not deliver a desktop alert. Watch snapshots are still being saved normally.")
        }
    }
}
