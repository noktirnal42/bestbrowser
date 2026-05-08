import SwiftUI

struct MediaSurfaceHero: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(description)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MediaSectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(BestBrowserBrand.border)
    }
}

struct MediaProviderCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let activeTint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(isSelected ? activeTint : BestBrowserBrand.border)
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? activeTint.opacity(0.12) : BestBrowserBrand.raisedCard)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? activeTint.opacity(0.7) : BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

struct MediaPresetCard: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BestBrowserBrand.border.opacity(0.75), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct MediaNowPlayingSummary: View {
    let eyebrow: String
    let title: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(tint)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
        }
    }
}

struct MediaNavigationButtons: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .foregroundColor(canGoBack ? BestBrowserBrand.primary : BestBrowserBrand.border)
            .disabled(!canGoBack)
            .help("Back")

            Button(action: onForward) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .foregroundColor(canGoForward ? BestBrowserBrand.primary : BestBrowserBrand.border)
            .disabled(!canGoForward)
            .help("Forward")
        }
    }
}

struct MediaVolumeControls: View {
    let isMuted: Bool
    let volume: Double
    let activeTint: Color
    let muteHelp: String
    let volumeHelp: String
    let onToggleMuted: () -> Void
    let onSetVolume: (Double) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggleMuted) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundColor(isMuted ? BestBrowserBrand.warning : activeTint)
            }
            .buttonStyle(.plain)
            .help(muteHelp)

            Slider(
                value: Binding(
                    get: { volume },
                    set: { onSetVolume($0) }
                ),
                in: 0...1
            )
            .frame(width: 120)
            .help(volumeHelp)
        }
    }
}

struct MediaActionChip: View {
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

struct MiniMediaIconButton: View {
    let systemName: String
    let tint: Color
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 28, height: 28)
                .background(BestBrowserBrand.raisedCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}

struct MiniMediaStripShell<Leading: View, Controls: View>: View {
    let leading: Leading
    let controls: Controls

    init(@ViewBuilder leading: () -> Leading, @ViewBuilder controls: () -> Controls) {
        self.leading = leading()
        self.controls = controls()
    }

    var body: some View {
        HStack(spacing: 16) {
            leading

            Rectangle()
                .fill(BestBrowserBrand.border.opacity(0.5))
                .frame(width: 1, height: 28)

            controls
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(BestBrowserBrand.chrome.opacity(0.98))
        .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.6)).frame(height: 1), alignment: .top)
    }
}
