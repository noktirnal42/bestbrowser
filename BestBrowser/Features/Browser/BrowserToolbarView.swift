import SwiftUI

struct BrandedToolbarView: View {
    let url: String
    let canGoBack: Bool
    let canGoForward: Bool
    let focusedTabTitle: String
    let focusedPaneLabel: String
    let onBack: () -> Void
    let onForward: () -> Void
    let onRefresh: () -> Void
    let onUrlChanged: (String) -> Void
    let onShowSettings: () -> Void
    let onOpenReadingMode: () -> Void
    let onRepairVideoLayout: () -> Void
    let onOpenDownloads: () -> Void
    let currentTabHasMedia: Bool
    let currentTabVolume: Double
    let currentTabMuted: Bool
    let onSetCurrentTabVolume: (Double) -> Void
    let onToggleCurrentTabMuted: () -> Void
    let isVideoPaneVisible: Bool
    let onToggleVideoPane: () -> Void
    let onResetVideoPane: () -> Void
    let toolbarExtensions: [BrowserExtension]
    let onRunExtension: (BrowserExtension) -> Void
    let onShowSplitPicker: () -> Void
    let recentClosedTabs: [ClosedTabRecord]
    let recentClosedSessions: [ClosedSessionRecord]
    let onReopenClosedTab: () -> Void
    let onReopenSpecificClosedTab: (ClosedTabRecord) -> Void
    let onRestoreClosedSession: (ClosedSessionRecord) -> Void

    @State private var urlText: String = ""
    @FocusState private var urlFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            ToolbarTitleCluster(
                focusedPaneLabel: focusedPaneLabel,
                focusedTabTitle: focusedTabTitle
            )

            ToolbarNavigationCluster(
                canGoBack: canGoBack,
                canGoForward: canGoForward,
                onBack: onBack,
                onForward: onForward,
                onRefresh: onRefresh
            )

            ToolbarAddressField(
                url: url,
                urlText: $urlText,
                isSecure: isSecureURL,
                isFocused: $urlFocused,
                onSubmit: submitURL,
                onClear: clearURLField
            )

            ToolbarSecurityBadge(isSecure: isSecureURL)

            ToolbarActionButton(
                icon: "book.pages.fill",
                tint: BestBrowserBrand.primary,
                helpText: "Open Reading Mode",
                action: onOpenReadingMode
            )

            if isYouTubeWatchPage {
                ToolbarActionButton(
                    icon: "rectangle.compress.vertical",
                    tint: BestBrowserBrand.secondary,
                    helpText: "Repair YouTube layout",
                    action: onRepairVideoLayout
                )
            }

            ToolbarActionButton(
                icon: "arrow.down.circle",
                tint: BestBrowserBrand.primary,
                helpText: "Open Downloads",
                action: onOpenDownloads
            )

            CurrentTabAudioControls(
                currentTabHasMedia: currentTabHasMedia,
                currentTabMuted: currentTabMuted,
                currentTabVolume: currentTabVolume,
                onSetCurrentTabVolume: onSetCurrentTabVolume,
                onToggleCurrentTabMuted: onToggleCurrentTabMuted
            )

            ToolbarActionButton(
                icon: isVideoPaneVisible ? "play.tv.fill" : "play.tv",
                tint: isVideoPaneVisible ? BestBrowserBrand.secondary : BestBrowserBrand.border,
                helpText: isVideoPaneVisible ? "Hide video pane" : "Show video pane",
                action: onToggleVideoPane
            )

            ToolbarActionButton(
                icon: "arrow.up.left.and.arrow.down.right.circle",
                tint: BestBrowserBrand.border,
                helpText: "Reset floating video pane position",
                action: onResetVideoPane
            )

            ToolbarExtensionsControl(
                toolbarExtensions: toolbarExtensions,
                onRunExtension: onRunExtension
            )

            ToolbarActionButton(
                icon: "rectangle.split.2x1",
                tint: BestBrowserBrand.primary,
                helpText: "Open Split View",
                action: onShowSplitPicker
            )

            RecentlyClosedToolbarMenu(
                recentClosedTabs: recentClosedTabs,
                recentClosedSessions: recentClosedSessions,
                onReopenClosedTab: onReopenClosedTab,
                onReopenSpecificClosedTab: onReopenSpecificClosedTab,
                onRestoreClosedSession: onRestoreClosedSession
            )

            ToolbarActionButton(
                icon: "gear",
                tint: BestBrowserBrand.border,
                helpText: "Settings",
                action: onShowSettings
            )
        }
        .padding(8)
        .background(BestBrowserBrand.chrome)
        .onAppear { urlText = url }
        .onReceive(NotificationCenter.default.publisher(for: .focusURLBar)) { _ in
            urlFocused = true
            urlText = ""
        }
    }

    private var isSecureURL: Bool {
        url.hasPrefix("https://")
    }

    private var isYouTubeWatchPage: Bool {
        url.contains("youtube.com/watch")
    }

    private func submitURL() {
        onUrlChanged(urlText)
        urlFocused = false
    }

    private func clearURLField() {
        urlText = ""
    }
}
