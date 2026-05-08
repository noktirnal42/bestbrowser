import SwiftUI

struct SettingsWindow: View {
    @State private var selectedTab: SettingsTab = .shield
    @StateObject private var settingsModel = SettingsViewModel()
    @StateObject private var themeManager = ThemeManager.shared

    enum SettingsTab: String, CaseIterable {
        case shield = "Privacy Shield"
        case privacy = "Privacy"
        case ai = "Apple Intelligence"
        case search = "Search"
        case data = "Data"
        case theme = "Theme"

        var icon: String {
            switch self {
            case .shield: return "shield.leeward.fill"
            case .privacy: return "hand.raised.fill"
            case .ai: return "sparkles"
            case .search: return "magnifyingglass"
            case .data: return "externaldrive.fill"
            case .theme: return "paintbrush.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                                .foregroundColor(selectedTab == tab ? BestBrowserBrand.primary : BestBrowserBrand.border)
                            Text(tab.rawValue)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(selectedTab == tab ? BestBrowserBrand.primary : BestBrowserBrand.border)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? BestBrowserBrand.primary.opacity(0.1) : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(BestBrowserBrand.darkCard)
            .border(BestBrowserBrand.border, width: 1)

            Divider().background(BestBrowserBrand.border)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .shield:
                        PrivacyDashboardView(privacyShield: PrivacyShield.shared)
                    case .privacy:
                        PrivacySettingsView(settings: settingsModel)
                    case .ai:
                        AISettingsView(settings: settingsModel)
                    case .search:
                        SearchSettingsView(settings: settingsModel)
                    case .data:
                        DataSettingsView(settings: settingsModel)
                    case .theme:
                        ThemeSettingsView(themeManager: themeManager)
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 700, height: 550)
        .background(BestBrowserBrand.darkBg)
    }
}

struct PrivacySettingsView: View {
    @ObservedObject var settings: SettingsViewModel
    @StateObject private var authService = BrowserAuthenticationService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "PRIVACY & SECURITY", icon: "hand.raised.fill")

            VStack(spacing: 12) {
            BrandedToggle(label: "Ad Blocking", isOn: $settings.adBlocking, icon: "xmark.shield.fill")
            BrandedToggle(label: "Tracker Blocking", isOn: $settings.trackerBlocking, icon: "eye.slash.fill")
            BrandedToggle(label: "Site Compatibility Mode", isOn: $settings.siteCompatibilityMode, icon: "globe.badge.chevron.backward")
            BrandedToggle(label: "HTTPS Upgrade", isOn: $settings.httpsUpgrade, icon: "lock.fill")
            BrandedToggle(label: "Send Do Not Track", isOn: $settings.doNotTrack, icon: "hand.raised")
            }
            .padding(12)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .cornerRadius(8)

            Text("Compatibility mode relaxes privacy blocking on complex web apps like YouTube, Slack, Docs, and Figma so missing panes and controls can render normally.")
                .font(.system(size: 11))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.78))

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.key.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(BestBrowserBrand.primary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Apple Passwords & Passkeys")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Text(authService.passkeyAccessStatus)
                            .font(.system(size: 12))
                            .foregroundColor(BestBrowserBrand.fog.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(authService.ssoStatus)
                            .font(.system(size: 11))
                            .foregroundColor(BestBrowserBrand.border)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    Button(action: { authService.requestPasskeyAccess() }) {
                        HStack(spacing: 6) {
                            Image(systemName: authService.isPasskeyAccessAuthorized ? "checkmark.shield.fill" : "key.fill")
                            Text(authService.isPasskeyAccessAuthorized ? "Refresh Access" : "Enable Access")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                    }
                    .buttonStyle(.cyberpunk)
                    .disabled(!authService.canRequestPasskeyAccess)
                    .help("Request access to Apple Passwords passkeys for websites in BestBrowser.")

                    Button(action: { authService.openPasswordsSettings() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                            Text("Open Passwords")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                    }
                    .buttonStyle(.cyberpunk)
                    .help("Open the Apple Passwords settings so you can manage passkeys and saved passwords.")
                }

                VStack(alignment: .leading, spacing: 6) {
                    BrandedHint(text: "BestBrowser web views already use shared persistent cookies, so Apple Passwords can fill sign-ins in browser, music, and video panes.")
                    BrandedHint(text: "Passkeys for arbitrary websites in WKWebView are handled by WebKit after the browser gets passkey access.")
                }
            }
            .padding(12)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .cornerRadius(8)
        }
    }
}

struct AISettingsView: View {
    @ObservedObject var settings: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "APPLE FOUNDATION MODEL", icon: "sparkles")

            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(BestBrowserBrand.primary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("On-device AI only")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Text("BestBrowser uses Apple's Foundation Models framework for summaries, translation, simplification, and page assistance. External LLM providers, API keys, and custom endpoints have been removed.")
                            .font(.system(size: 12))
                            .foregroundColor(BestBrowserBrand.fog.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("STATUS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.border)

                    Text(settings.aiStatusMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BestBrowserBrand.darkCard)
                        .border(BestBrowserBrand.border, width: 0.5)
                        .cornerRadius(6)
                }

                HStack {
                    Button(action: { Task { await settings.testConnection() } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                            Text("Test Connection")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                    }
                    .buttonStyle(.cyberpunk)

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(connectionColor)
                            .frame(width: 8, height: 8)
                            .neonGlow(connectionColor, radius: 3)
                        Text(connectionText)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(connectionColor)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("REQUIREMENTS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.border)

                    BrandedHint(text: "Requires macOS 26+ and Apple Intelligence enabled on a supported Mac.")
                    BrandedHint(text: "All AI features now run through Apple's on-device Foundation Model.")
                }
                .padding(10)
                .background(BestBrowserBrand.darkCard)
                .border(BestBrowserBrand.border, width: 0.5)
                .cornerRadius(6)
            }
            .padding(12)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .cornerRadius(8)
        }
    }

    private var connectionColor: Color {
        switch settings.connectionStatus {
        case .connected: return BestBrowserBrand.success
        case .failed: return BestBrowserBrand.error
        case .testing: return BestBrowserBrand.warning
        case .unknown: return BestBrowserBrand.border
        }
    }

    private var connectionText: String {
        switch settings.connectionStatus {
        case .connected: return "Connected"
        case .failed: return "Failed"
        case .testing: return "Testing..."
        case .unknown: return "Ready"
        }
    }
}

struct SearchSettingsView: View {
    @ObservedObject var settings: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "SEARCH ENGINE", icon: "magnifyingglass")

            VStack(spacing: 12) {
                ForEach([("duckduckgo", "DuckDuckGo"), ("brave", "Brave Search"), ("google", "Google"), ("bing", "Bing"), ("custom", "Custom")], id: \.0) { tag, label in
                    Button(action: { settings.searchEngine = tag }) {
                        HStack {
                            Image(systemName: settings.searchEngine == tag ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(settings.searchEngine == tag ? BestBrowserBrand.primary : BestBrowserBrand.border)
                                .font(.system(size: 12))
                            Text(label)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(settings.searchEngine == tag ? BestBrowserBrand.primary : .white)
                            Spacer()
                        }
                        .padding(8)
                        .background(settings.searchEngine == tag ? BestBrowserBrand.primary.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }

                if settings.searchEngine == "custom" {
                    BrandedTextField(label: "Custom Search URL", text: $settings.customSearchUrl, icon: "link")
                }
            }
            .padding(12)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .cornerRadius(8)
        }
    }
}

struct ThemeSettingsView: View {
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "APPEARANCE", icon: "paintbrush.fill")

            VStack(spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    Button(action: { themeManager.currentTheme = theme }) {
                        HStack {
                            Image(systemName: themeManager.currentTheme == theme ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(themeManager.currentTheme == theme ? BestBrowserBrand.primary : BestBrowserBrand.border)
                                .font(.system(size: 12))
                            Image(systemName: theme.icon)
                                .foregroundColor(BestBrowserBrand.secondary)
                                .font(.system(size: 12))
                            Text(theme.displayName)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(themeManager.currentTheme == theme ? BestBrowserBrand.primary : .white)
                            Spacer()
                        }
                        .padding(8)
                        .background(themeManager.currentTheme == theme ? BestBrowserBrand.primary.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }

                BrandedHint(text: "Choose 'System' to automatically match your macOS appearance.")
            }
            .padding(12)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .cornerRadius(8)
        }
    }
}

struct DataSettingsView: View {
    @ObservedObject var settings: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "DATA MANAGEMENT", icon: "externaldrive.fill")

            VStack(spacing: 12) {
                Text("Manage your local browser data. These actions are permanent.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)

                HStack(spacing: 12) {
                    Button("Clear History") { settings.clearHistory() }
                        .buttonStyle(.cyberpunk)
                    Button("Clear Search Index") { settings.clearIndex() }
                        .buttonStyle(.cyberpunk)
                }
            }
            .padding(12)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .cornerRadius(8)
        }
    }
}

// MARK: - Reusable Branded Components

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(BestBrowserBrand.secondary)
                .neonGlow(BestBrowserBrand.secondary, radius: 3)
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
        }
    }
}

struct BrandedToggle: View {
    let label: String
    @Binding var isOn: Bool
    var icon: String = ""

    var body: some View {
        HStack {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundColor(BestBrowserBrand.secondary)
                    .font(.system(size: 12))
                    .frame(width: 20)
            }
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(BestBrowserBrand.success)
        }
    }
}

struct BrandedTextField: View {
    let label: String
    @Binding var text: String
    var icon: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .foregroundColor(BestBrowserBrand.border)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
            }
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
                .padding(8)
                .background(BestBrowserBrand.darkCard)
                .border(BestBrowserBrand.border, width: 1)
                .cornerRadius(4)
        }
    }
}

struct BrandedSecureField: View {
    let label: String
    @Binding var text: String
    var icon: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .foregroundColor(BestBrowserBrand.border)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
            }
            SecureField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
                .padding(8)
                .background(BestBrowserBrand.darkCard)
                .border(BestBrowserBrand.border, width: 1)
                .cornerRadius(4)
        }
    }
}

struct BrandedHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(BestBrowserBrand.border)
    }
}

#Preview {
    SettingsWindow()
}
