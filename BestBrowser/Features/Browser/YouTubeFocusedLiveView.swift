import SwiftUI
import AppKit

struct YouTubeFocusedLiveView: View {
    let tab: BrowserTab
    let embedURL: String
    let browserModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE FOCUS MODE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.secondary)
                    Text("YouTube live chat is blocked in this embedded browser, so BestBrowser is showing a clean player instead.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button("Standard Page") {
                    browserModel.disableYouTubeFocusedLiveMode(for: tab.id)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.border)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BestBrowserBrand.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BestBrowserBrand.border.opacity(0.6), lineWidth: 1)
                )

                Button("Open in Safari") {
                    guard let url = URL(string: tab.url) else { return }
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BestBrowserBrand.primary.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BestBrowserBrand.primary.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(BestBrowserBrand.chrome.opacity(0.96))
            .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.4)).frame(height: 1), alignment: .bottom)

            FocusedPlayerWebViewWrapper(
                url: embedURL,
                tabId: tab.id,
                viewModel: browserModel
            )
        }
        .background(BestBrowserBrand.darkBg)
    }
}
