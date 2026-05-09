import SwiftUI

struct SplitBrowserContentView: View {
    let primaryTab: BrowserTab
    let secondaryTab: BrowserTab
    let browserModel: BrowserViewModel

    var body: some View {
        HSplitView {
            SplitBrowserPaneView(
                tab: primaryTab,
                label: "Primary",
                browserModel: browserModel
            )
            SplitBrowserPaneView(
                tab: secondaryTab,
                label: "Reference",
                browserModel: browserModel
            )
        }
    }
}

private struct SplitBrowserPaneView: View {
    let tab: BrowserTab
    let label: String
    let browserModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
                Circle()
                    .fill(tab.id == browserModel.activeTabId ? BestBrowserBrand.secondary : BestBrowserBrand.border.opacity(0.5))
                    .frame(width: 6, height: 6)
                Text(tab.title.isEmpty ? tab.url : tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Button("Focus") {
                    browserModel.selectTab(tab.id)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BestBrowserBrand.chrome)
            .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.45)).frame(height: 1), alignment: .bottom)

            if browserModel.isNewTab(tab) {
                NewTabHomeView(
                    onOpen: { target in
                        browserModel.selectTab(tab.id)
                        browserModel.loadUrl(target, for: tab.id)
                    },
                    activeTabId: tab.id
                )
            } else {
                SplitBrowserSurfaceView(tab: tab, browserModel: browserModel)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            browserModel.selectTab(tab.id)
        }
    }
}

private struct SplitBrowserSurfaceView: View {
    let tab: BrowserTab
    let browserModel: BrowserViewModel

    var body: some View {
        if browserModel.isYouTubeFocusedLiveMode(for: tab.id),
           let embedURL = browserModel.youTubeEmbedURL(for: tab) {
            YouTubeFocusedLiveView(
                tab: tab,
                embedURL: embedURL,
                browserModel: browserModel
            )
        } else {
            WebViewWrapper(url: tab.url, tabId: tab.id, viewModel: browserModel)
        }
    }
}
