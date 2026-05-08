import SwiftUI

struct SidebarRailView: View {
    @Binding var selection: BrowserWorkspaceStore.SurfaceMode
    let isVisible: Bool
    let onToggleVisibility: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onToggleVisibility) {
                    Image(systemName: isVisible ? "sidebar.left" : "sidebar.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(BestBrowserBrand.primary)
                        .padding(8)
                        .background(BestBrowserBrand.raisedCard)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .help("Hide main navigation")
                .padding(.top, 10)
                .padding(.trailing, 10)
            }

            List(selection: $selection) {
                Label("Browser", systemImage: "globe")
                    .tag(BrowserWorkspaceStore.SurfaceMode.browser)
                    .help("Open the main browsing workspace")
                Label("Workspaces", systemImage: "square.stack.3d.up")
                    .tag(BrowserWorkspaceStore.SurfaceMode.workspaces)
                    .help("Browse and restore saved research workspaces")
                Label("Watchlist", systemImage: "eye")
                    .tag(BrowserWorkspaceStore.SurfaceMode.watches)
                    .help("Review watched pages and change summaries")
                Label("Memory", systemImage: "brain")
                    .tag(BrowserWorkspaceStore.SurfaceMode.memory)
                    .help("Search saved page memory and pinned notes")
                Label("Extensions", systemImage: "puzzlepiece.extension")
                    .tag(BrowserWorkspaceStore.SurfaceMode.extensions)
                    .help("Manage built-in and custom BestBrowser extensions")
                Label("Music", systemImage: "music.note.house")
                    .tag(BrowserWorkspaceStore.SurfaceMode.music)
                    .help("Open the dedicated music player surface")
                Label("Video", systemImage: "play.tv")
                    .tag(BrowserWorkspaceStore.SurfaceMode.video)
                    .help("Open the dedicated video player surface")
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("BestBrowser")
        .frame(minWidth: 220, idealWidth: 240)
    }
}
