import SwiftUI

struct BrowserSceneRootView: View {
    @State private var store = BrowserWorkspaceStore()
    @StateObject private var workspaceService = WorkspaceService.shared
    @StateObject private var watchService = WatchService.shared
    @StateObject private var memoryService = PageMemoryService.shared
    @StateObject private var extensionHost = BrowserExtensionHost.shared
    @StateObject private var musicStore = MusicPlayerStore.shared
    @StateObject private var videoStore = VideoPlayerStore.shared

    var body: some View {
        GeometryReader { proxy in
            let musicBarVisible = musicStore.isPinnedToBottomBar && store.surfaceMode != .music
            let videoBottomPadding: CGFloat = musicBarVisible ? 72 : 24

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if store.sidebarVisible {
                        SidebarRailView(
                            selection: Binding(
                                get: { store.surfaceMode },
                                set: { store.navigate(to: $0) }
                            ),
                            isVisible: store.sidebarVisible,
                            onToggleVisibility: { store.toggleSidebar() }
                        )
                        .frame(width: 240)

                        Rectangle()
                            .fill(BestBrowserBrand.border.opacity(0.6))
                            .frame(width: 1)
                    } else {
                        VStack(spacing: 0) {
                            HStack {
                                Button(action: { store.toggleSidebar() }) {
                                    Image(systemName: "sidebar.left")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(BestBrowserBrand.primary)
                                        .padding(10)
                                        .background(BestBrowserBrand.chrome.opacity(0.96))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .help("Show main navigation")

                                Spacer()
                            }
                            .padding(.top, 12)
                            .padding(.horizontal, 10)

                            Spacer()
                        }
                        .frame(width: 56)
                        .background(BestBrowserBrand.darkBg)

                        Rectangle()
                            .fill(BestBrowserBrand.border.opacity(0.6))
                            .frame(width: 1)
                    }

                    Group {
                        switch store.surfaceMode {
                        case .browser:
                            BrowserShellView()
                        case .workspaces:
                            WorkspaceSidebarView(workspaceService: workspaceService)
                                .background(BestBrowserBrand.darkBg)
                        case .watches:
                            WatchListView(watchService: watchService)
                                .background(BestBrowserBrand.darkBg)
                        case .memory:
                            MemoryLibraryView(memoryService: memoryService)
                        case .extensions:
                            ExtensionsLibraryView(extensionHost: extensionHost)
                        case .music:
                            MusicPlayerView {
                                store.navigate(to: .browser)
                            }
                        case .video:
                            VideoPlayerView {
                                store.navigate(to: .browser)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(BestBrowserBrand.darkBg)
                }

                if musicBarVisible {
                    MiniMusicPlayerStrip(store: musicStore) {
                        store.navigate(to: .music)
                    }
                }
            }
            .overlay(alignment: videoStore.panePosition.alignment) {
                if videoStore.isPinnedPaneVisible && store.surfaceMode != .video {
                    FloatingVideoPane(store: videoStore) {
                        store.navigate(to: .video)
                    }
                    .padding(.trailing, 24)
                    .padding(.top, videoStore.panePosition == .topRight ? 24 : 0)
                    .padding(.bottom, videoStore.panePosition == .bottomRight ? videoBottomPadding : 0)
                    .offset(x: videoStore.paneOffsetX, y: videoStore.paneOffsetY)
                }
            }
            .onAppear {
                videoStore.clampPaneOffset(in: proxy.size, topPadding: 88, bottomPadding: videoBottomPadding)
            }
            .onChange(of: proxy.size) { _, newSize in
                videoStore.clampPaneOffset(in: newSize, topPadding: 88, bottomPadding: videoBottomPadding)
            }
            .onChange(of: videoStore.isPinnedPaneVisible) { _, _ in
                videoStore.clampPaneOffset(in: proxy.size, topPadding: 88, bottomPadding: videoBottomPadding)
            }
            .onChange(of: videoStore.isPinnedPaneCollapsed) { _, _ in
                videoStore.clampPaneOffset(in: proxy.size, topPadding: 88, bottomPadding: videoBottomPadding)
            }
            .onChange(of: videoStore.paneSize) { _, _ in
                videoStore.clampPaneOffset(in: proxy.size, topPadding: 88, bottomPadding: videoBottomPadding)
            }
            .onChange(of: videoStore.panePosition) { _, _ in
                videoStore.clampPaneOffset(in: proxy.size, topPadding: 88, bottomPadding: videoBottomPadding)
            }
        }
    }
}
