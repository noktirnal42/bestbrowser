import SwiftUI

struct PrivacyDashboardView: View {
    @ObservedObject var privacyShield: PrivacyShield

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.leeward.fill")
                            .foregroundColor(privacyShield.isEnabled ? BestBrowserBrand.success : BestBrowserBrand.border)
                            .neonGlow(privacyShield.isEnabled ? BestBrowserBrand.success : .clear, radius: 4)
                        Text("PRIVACY SHIELD")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.primary)
                    }

                    Text(privacyShield.isEnabled ? "Active & Protecting" : "Disabled")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(privacyShield.isEnabled ? BestBrowserBrand.success : BestBrowserBrand.border)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { privacyShield.isEnabled },
                    set: { _ in privacyShield.toggle() }
                ))
                .toggleStyle(.switch)
                .tint(BestBrowserBrand.success)
            }
            .padding()
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)
            .cornerRadius(8)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatCard(icon: "xmark.circle.fill", value: String(privacyShield.stats.blockedCount), label: "Blocked", color: BestBrowserBrand.error)
                    StatCard(icon: "speedometer", value: privacyShield.stats.formattedTimeSaved(), label: "Time Saved", color: BestBrowserBrand.info)
                }

                HStack(spacing: 12) {
                    StatCard(icon: "hand.raised.fill", value: String(privacyShield.stats.adsBlocked), label: "Ads Blocked", color: BestBrowserBrand.warning)
                    StatCard(icon: "eye.slash.fill", value: String(privacyShield.stats.trackersBlocked), label: "Trackers Blocked", color: BestBrowserBrand.accent)
                }
            }

            Divider().background(BestBrowserBrand.border)

            VStack(spacing: 12) {
                Toggle("Ad Blocking", isOn: Binding(
                    get: { privacyShield.adBlockingEnabled },
                    set: { _ in privacyShield.toggleAdBlocking() }
                ))
                .tint(BestBrowserBrand.success)

                Toggle("Tracker Blocking", isOn: Binding(
                    get: { privacyShield.trackerBlockingEnabled },
                    set: { _ in privacyShield.toggleTrackerBlocking() }
                ))
                .tint(BestBrowserBrand.success)

                Button("Reset Statistics") {
                    privacyShield.resetStats()
                }
                .buttonStyle(.cyberpunk)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Spacer()
        }
        .padding()
        .background(BestBrowserBrand.darkBg)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .neonGlow(color, radius: 4)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.border)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(BestBrowserBrand.cardBackground)
        .border(BestBrowserBrand.border, width: 1)
        .cornerRadius(8)
    }
}

#Preview {
    PrivacyDashboardView(privacyShield: PrivacyShield.shared)
}
