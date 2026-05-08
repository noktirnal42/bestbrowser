import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var adBlocking: Bool = true
    @Published var trackerBlocking: Bool = true
    @Published var siteCompatibilityMode: Bool = true
    @Published var httpsUpgrade: Bool = true
    @Published var doNotTrack: Bool = true

    @Published var searchEngine: String = "duckduckgo"
    @Published var customSearchUrl: String = ""

    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var aiStatusMessage: String = "Apple Intelligence status unknown."

    let storage = StorageManager.shared
    let privacyShield = PrivacyShield.shared
    private var cancellables = Set<AnyCancellable>()

    enum ConnectionStatus {
        case unknown
        case testing
        case connected
        case failed
    }

    init() {
        loadSettings()
        bindSettings()
    }

    func loadSettings() {
        let userDefaults = UserDefaults.standard
        adBlocking = userDefaults.object(forKey: "adBlocking") as? Bool ?? true
        trackerBlocking = userDefaults.object(forKey: "trackerBlocking") as? Bool ?? true
        siteCompatibilityMode = userDefaults.object(forKey: "siteCompatibilityMode") as? Bool ?? true
        httpsUpgrade = userDefaults.object(forKey: "httpsUpgrade") as? Bool ?? true
        doNotTrack = userDefaults.object(forKey: "doNotTrack") as? Bool ?? true
        searchEngine = userDefaults.string(forKey: "searchEngine") ?? "duckduckgo"
        customSearchUrl = userDefaults.string(forKey: "customSearchUrl") ?? ""

        privacyShield.adBlockingEnabled = adBlocking
        privacyShield.trackerBlockingEnabled = trackerBlocking
        updateAIStatusMessage()
    }

    func saveSettings() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(adBlocking, forKey: "adBlocking")
        userDefaults.set(trackerBlocking, forKey: "trackerBlocking")
        userDefaults.set(siteCompatibilityMode, forKey: "siteCompatibilityMode")
        userDefaults.set(httpsUpgrade, forKey: "httpsUpgrade")
        userDefaults.set(doNotTrack, forKey: "doNotTrack")
        userDefaults.set(searchEngine, forKey: "searchEngine")
        userDefaults.set(customSearchUrl, forKey: "customSearchUrl")

        privacyShield.adBlockingEnabled = adBlocking
        privacyShield.trackerBlockingEnabled = trackerBlocking
    }

    func testConnection() async {
        let client = AIClient.shared
        connectionStatus = .testing

        do {
            let success = try await client.testConnection()
            connectionStatus = success ? .connected : .failed
            updateAIStatusMessage()
        } catch {
            connectionStatus = .failed
            aiStatusMessage = error.localizedDescription
        }
    }

    func clearHistory() {
        Task {
            try? await storage.clearHistory()
        }
    }

    func clearIndex() {
        Task {
            try? await SemanticSearch.shared.clearIndex()
        }
    }

    private func bindSettings() {
        Publishers.CombineLatest4($adBlocking, $trackerBlocking, $siteCompatibilityMode, $httpsUpgrade)
            .dropFirst()
            .sink { [weak self] _, _, _, _ in self?.saveSettings() }
            .store(in: &cancellables)

        $doNotTrack
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        Publishers.CombineLatest($searchEngine, $customSearchUrl)
            .dropFirst()
            .sink { [weak self] _, _ in self?.saveSettings() }
            .store(in: &cancellables)
    }

    private func updateAIStatusMessage() {
        AIClient.shared.refreshAvailability()
        aiStatusMessage = {
            switch AIClient.shared.availability {
            case .available:
                return "Apple Foundation Model is ready on this Mac."
            case .unavailable(let reason):
                switch reason {
                case .deviceNotEligible:
                    return "This Mac does not support Apple Intelligence."
                case .appleIntelligenceNotEnabled:
                    return "Turn on Apple Intelligence in macOS settings to enable AI features."
                case .modelNotReady:
                    return "Apple Intelligence is still preparing the on-device model."
                @unknown default:
                    return "Apple Intelligence is currently unavailable on this Mac."
                }
            }
        }()
    }
}
