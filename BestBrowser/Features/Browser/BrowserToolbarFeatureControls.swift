import SwiftUI

struct CurrentTabAudioControls: View {
    let currentTabHasMedia: Bool
    let currentTabMuted: Bool
    let currentTabVolume: Double
    let onSetCurrentTabVolume: (Double) -> Void
    let onToggleCurrentTabMuted: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggleCurrentTabMuted) {
                Image(systemName: currentTabMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 11))
                    .foregroundColor(iconTint)
            }
            .buttonStyle(.plain)
            .disabled(!currentTabHasMedia)
            .help(muteHelpText)

            Slider(
                value: Binding(
                    get: { currentTabVolume },
                    set: { value in onSetCurrentTabVolume(value) }
                ),
                in: 0...1
            )
            .frame(width: 90)
            .disabled(!currentTabHasMedia)
            .help(currentTabHasMedia ? "Current tab volume" : "No media detected in the current tab")
        }
    }

    private var iconTint: Color {
        guard currentTabHasMedia else { return BestBrowserBrand.border }
        return currentTabMuted ? BestBrowserBrand.warning : BestBrowserBrand.primary
    }

    private var muteHelpText: String {
        guard currentTabHasMedia else { return "No media detected in the current tab" }
        return currentTabMuted ? "Unmute current tab" : "Mute current tab"
    }
}

struct ToolbarExtensionsControl: View {
    let toolbarExtensions: [BrowserExtension]
    let onRunExtension: (BrowserExtension) -> Void

    var body: some View {
        if toolbarExtensions.count <= 2 {
            ForEach(toolbarExtensions) { ext in
                Button(action: { onRunExtension(ext) }) {
                    Image(systemName: ext.icon)
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.secondary)
                }
                .buttonStyle(.plain)
                .help(ext.name)
            }
        } else if !toolbarExtensions.isEmpty {
            Menu {
                ForEach(toolbarExtensions) { ext in
                    Button(action: { onRunExtension(ext) }) {
                        Label(ext.name, systemImage: ext.icon)
                    }
                }
            } label: {
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.secondary)
            }
            .menuStyle(.borderlessButton)
            .help("Page tools")
        }
    }
}

struct RecentlyClosedToolbarMenu: View {
    let recentClosedTabs: [ClosedTabRecord]
    let recentClosedSessions: [ClosedSessionRecord]
    let onReopenClosedTab: () -> Void
    let onReopenSpecificClosedTab: (ClosedTabRecord) -> Void
    let onRestoreClosedSession: (ClosedSessionRecord) -> Void

    var body: some View {
        Menu {
            Button(action: onReopenClosedTab) {
                Label("Reopen Last Closed Tab", systemImage: "arrow.uturn.backward")
            }
            .disabled(recentClosedTabs.isEmpty)

            if !recentClosedTabs.isEmpty {
                Divider()
                ForEach(recentClosedTabs.prefix(8)) { tab in
                    Button(action: { onReopenSpecificClosedTab(tab) }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tab.title.isEmpty ? tab.url : tab.title)
                            Text(tab.url)
                        }
                    }
                }
            }

            if !recentClosedSessions.isEmpty {
                Divider()
                ForEach(recentClosedSessions.prefix(6)) { session in
                    Button(action: { onRestoreClosedSession(session) }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Restore: \(session.title)")
                            Text("\(session.snapshot.tabs.count) tabs • \(session.closedAt.formatted(date: .omitted, time: .shortened))")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 11))
                .foregroundColor(BestBrowserBrand.primary)
        }
        .menuStyle(.borderlessButton)
        .help("Recently closed tabs and sessions")
    }
}
