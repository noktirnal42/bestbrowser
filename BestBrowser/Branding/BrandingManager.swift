import SwiftUI

struct BestBrowserBrand {
    // MARK: - Private Atelier Palette
    static let signalBlue = Color(red: 0.30, green: 0.63, blue: 0.63)
    static let signalSky = Color(red: 0.93, green: 0.85, blue: 0.72)
    static let signalAmber = Color(red: 0.91, green: 0.47, blue: 0.28)
    static let fog = Color(red: 0.95, green: 0.92, blue: 0.87)
    static let darkBg = Color(red: 0.07, green: 0.07, blue: 0.08)
    static let darkCard = Color(red: 0.12, green: 0.11, blue: 0.12)
    static let darkBorder = Color(red: 0.24, green: 0.21, blue: 0.19)
    static let raisedCard = Color(red: 0.16, green: 0.14, blue: 0.14)
    static let chrome = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let glow = Color(red: 0.88, green: 0.56, blue: 0.31)

    // MARK: - Primary Colors
    static let primary = signalSky
    static let secondary = signalAmber
    static let accent = signalBlue
    static let background = darkBg
    static let cardBackground = darkCard
    static let border = darkBorder

    // MARK: - Utility Colors
    static let success = Color(red: 0.45, green: 0.74, blue: 0.58)
    static let warning = Color(red: 0.92, green: 0.73, blue: 0.33)
    static let error = Color(red: 0.88, green: 0.36, blue: 0.30)
    static let info = signalBlue

    // MARK: - Typography
    static let font = "SF Mono"
    static let displayFont = "New York"

    // MARK: - Branding Assets
    static let appName = "BestBrowser"
    static let appVersion = AppVersion.displayVersion
    static let tagline = "Quiet focus. Your web."
}

// MARK: - Custom View Modifiers

struct NeonGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.18), radius: radius)
            .shadow(color: color.opacity(0.08), radius: radius * 2)
    }
}

struct CyberpunkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(BestBrowserBrand.secondary.opacity(configuration.isPressed ? 0.16 : 0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BestBrowserBrand.secondary.opacity(0.55), lineWidth: 1)
            )
            .cornerRadius(12)
            .foregroundColor(BestBrowserBrand.primary)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct CyberpunkCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(BestBrowserBrand.border.opacity(0.9), lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.16), radius: 12, y: 6)
    }
}

// MARK: - Extensions

extension View {
    func neonGlow(_ color: Color = BestBrowserBrand.signalSky, radius: CGFloat = 8) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius))
    }

    func cyberpunkCard() -> some View {
        modifier(CyberpunkCardStyle())
    }
}

extension ButtonStyle where Self == CyberpunkButtonStyle {
    static var cyberpunk: Self {
        CyberpunkButtonStyle()
    }
}

// MARK: - Startup Screen

struct StartupScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [BestBrowserBrand.darkBg, BestBrowserBrand.darkCard, BestBrowserBrand.accent.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [BestBrowserBrand.glow.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Group {
                        if BrandGraphicView.exists(named: "launch-badge") {
                            BrandGraphicView(resourceName: "launch-badge", width: 132, height: 132)
                        } else {
                            AppIconView(size: 132)
                        }
                    }
                    .shadow(color: BestBrowserBrand.glow.opacity(0.24), radius: 24)

                    VStack(spacing: 10) {
                        Text(BestBrowserBrand.appName)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(BestBrowserBrand.fog)

                        Text(BestBrowserBrand.tagline.uppercased())
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .tracking(2.4)
                            .foregroundColor(BestBrowserBrand.primary.opacity(0.92))
                    }

                    Text(BestBrowserBrand.tagline)
                        .font(.caption)
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.72))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 12) {
                    ProgressView()
                        .tint(BestBrowserBrand.primary)

                    Text("Calibrating private browsing systems...")
                        .font(.caption)
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.7))
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    StartupScreenView()
}
