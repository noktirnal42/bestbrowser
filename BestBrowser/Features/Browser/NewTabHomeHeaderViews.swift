import SwiftUI

struct NewTabHeroSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if BrandGraphicView.exists(named: "launch-badge") {
                    BrandGraphicView(resourceName: "launch-badge", width: 84, height: 84)
                } else {
                    AppIconView(size: 84)
                }
            }

            Text("BestBrowser")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("A browser shaped for your own headspace.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.75))

            HStack(spacing: 10) {
                Text("PERSONAL BROWSER")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.secondary)
                Capsule()
                    .fill(BestBrowserBrand.border.opacity(0.8))
                    .frame(width: 54, height: 1)
                Text("quiet by default")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.62))
            }
        }
    }
}

struct NewTabSearchField: View {
    @Binding var searchText: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(BestBrowserBrand.secondary)

            TextField("Search the web or enter a URL", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.white)
                .onSubmit {
                    onSubmit()
                }
        }
        .padding(14)
        .background(BestBrowserBrand.raisedCard)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BestBrowserBrand.secondary.opacity(0.34), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct HomeMetricsRow: View {
    let bookmarkCount: Int
    let recentPageCount: Int
    let workspaceCount: Int
    let aiReady: Bool

    var body: some View {
        HStack(spacing: 12) {
            HomeBadge(title: "Bookmarks", value: "\(bookmarkCount)", icon: "bookmark.fill")
            HomeBadge(title: "Recent Pages", value: "\(recentPageCount)", icon: "clock.fill")
            HomeBadge(title: "Workspaces", value: "\(workspaceCount)", icon: "square.stack.3d.up.fill")
            HomeBadge(title: "On-device AI", value: aiReady ? "Ready" : "Off", icon: "sparkles")
        }
    }
}

private struct HomeBadge: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(BestBrowserBrand.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BestBrowserBrand.raisedCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}
