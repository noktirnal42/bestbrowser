import SwiftUI
import AppKit
import Combine

struct MusicPreset: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let url: String
}

enum MusicProvider: String, CaseIterable, Identifiable {
    case difm = "DI.fm"
    case spotify = "Spotify"
    case appleMusic = "Apple Music"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .difm: return "dot.radiowaves.left.and.right"
        case .spotify: return "music.note.list"
        case .appleMusic: return "apple.logo"
        }
    }

    var subtitle: String {
        switch self {
        case .difm:
            return "Internet radio, long-form sets, and channel surfing."
        case .spotify:
            return "Web player for playlists, discovery, and your library."
        case .appleMusic:
            return "Apple Music web player with your account and recommendations."
        }
    }

    var homeURL: String {
        switch self {
        case .difm:
            return "https://www.di.fm/"
        case .spotify:
            return "https://open.spotify.com/"
        case .appleMusic:
            return "https://music.apple.com/"
        }
    }

    var presets: [MusicPreset] {
        switch self {
        case .difm:
            return [
                MusicPreset(id: "difm-jungle", title: "Jungle", subtitle: "Breakbeat energy with a little chaos", url: "https://www.di.fm/jungle"),
                MusicPreset(id: "difm-space-dreams", title: "Space Dreams", subtitle: "Ambient drift for late-night focus", url: "https://www.di.fm/spacemusic"),
                MusicPreset(id: "difm-progressive", title: "Progressive", subtitle: "Long-form build and flow", url: "https://www.di.fm/progressive")
            ]
        case .spotify:
            return [
                MusicPreset(id: "spotify-home", title: "Home", subtitle: "Jump back into recommendations", url: "https://open.spotify.com/"),
                MusicPreset(id: "spotify-search", title: "Search", subtitle: "Find an album, artist, or playlist", url: "https://open.spotify.com/search"),
                MusicPreset(id: "spotify-collection", title: "Your Library", subtitle: "Saved albums and playlists", url: "https://open.spotify.com/collection/playlists")
            ]
        case .appleMusic:
            return [
                MusicPreset(id: "apple-home", title: "Home", subtitle: "Recommendations and recently played", url: "https://music.apple.com/"),
                MusicPreset(id: "apple-browse", title: "Browse", subtitle: "Editorial picks and charts", url: "https://music.apple.com/browse"),
                MusicPreset(id: "apple-radio", title: "Radio", subtitle: "Stations and live programming", url: "https://music.apple.com/radio")
            ]
        }
    }
}

@MainActor
final class MusicPlayerStore: ObservableObject {
    static let shared = MusicPlayerStore()

    @Published var selectedProvider: MusicProvider
    @Published var isPinnedToBottomBar = true

    let player: PersistentWebPlayer

    private let providerKey = "bestbrowser.music.provider"
    private let pinnedKey = "bestbrowser.music.pinned"
    private let urlKeyPrefix = "bestbrowser.music.url."
    private var cancellables: Set<AnyCancellable> = []
    private var playbackNudgeTask: Task<Void, Never>?

    init() {
        let raw = UserDefaults.standard.string(forKey: providerKey)
        let provider = MusicProvider(rawValue: raw ?? "") ?? .difm
        self.selectedProvider = provider
        let initialURL = UserDefaults.standard.string(forKey: "\(urlKeyPrefix)\(provider.rawValue)") ?? provider.homeURL
        self.player = PersistentWebPlayer(initialURL: initialURL, fallbackTitle: "Music")
        self.isPinnedToBottomBar = UserDefaults.standard.object(forKey: pinnedKey) as? Bool ?? true

        player.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        player.$currentURL
            .sink { [weak self] url in
                guard let self else { return }
                UserDefaults.standard.set(url, forKey: "\(self.urlKeyPrefix)\(self.selectedProvider.rawValue)")
            }
            .store(in: &cancellables)
    }

    func selectProvider(_ provider: MusicProvider) {
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: providerKey)
        player.navigate(to: UserDefaults.standard.string(forKey: "\(urlKeyPrefix)\(provider.rawValue)") ?? provider.homeURL)
        nudgePlaybackIfNeeded()
    }

    func navigate(to url: String) {
        player.navigate(to: url)
        nudgePlaybackIfNeeded()
    }

    func reload() {
        player.reload()
        nudgePlaybackIfNeeded()
    }

    func goHome() {
        player.navigate(to: selectedProvider.homeURL)
        nudgePlaybackIfNeeded()
    }

    func togglePinned() {
        isPinnedToBottomBar.toggle()
        UserDefaults.standard.set(isPinnedToBottomBar, forKey: pinnedKey)
    }

    var presets: [MusicPreset] {
        selectedProvider.presets
    }

    var currentURL: String { player.currentURL }
    var pageTitle: String { player.pageTitle }
    var volume: Double { player.volume }
    var isMuted: Bool { player.isMuted }

    func setVolume(_ volume: Double) {
        player.setVolume(volume)
    }

    func toggleMuted() {
        player.toggleMuted()
    }

    private func nudgePlaybackIfNeeded() {
        playbackNudgeTask?.cancel()
        guard selectedProvider == .difm else { return }

        playbackNudgeTask = Task { @MainActor in
            let delays = [600, 1200, 2200, 3600]
            for delay in delays {
                try? await Task.sleep(for: .milliseconds(delay))
                guard !Task.isCancelled else { return }
                player.attemptPlayback()
                player.refreshPlaybackState()
            }
        }
    }
}

struct MusicPlayerView: View {
    @StateObject private var store = MusicPlayerStore.shared
    let onReturnToBrowser: () -> Void
    private let providerColumns = [GridItem(.adaptive(minimum: 220), spacing: 12)]
    private let presetColumns = [GridItem(.adaptive(minimum: 180), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            header
            PersistentWebPlayerContainer(player: store.player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BestBrowserBrand.darkBg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            MediaSurfaceHero(
                title: "Music",
                description: "Keep a dedicated music service running while you browse. Use DI.fm, Spotify, or Apple Music as a persistent listening space without turning the whole browser into a media tab."
            )

            LazyVGrid(columns: providerColumns, alignment: .leading, spacing: 12) {
                ForEach(MusicProvider.allCases) { provider in
                    MediaProviderCard(
                        title: provider.rawValue,
                        subtitle: provider.subtitle,
                        icon: provider.icon,
                        isSelected: provider == store.selectedProvider,
                        activeTint: BestBrowserBrand.primary
                    ) {
                        store.selectProvider(provider)
                    }
                    .help("Switch music provider to \(provider.rawValue)")
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                MediaSectionLabel(title: "Quick Picks")

                LazyVGrid(columns: presetColumns, alignment: .leading, spacing: 12) {
                    ForEach(store.presets) { preset in
                        MediaPresetCard(
                            title: preset.title,
                            subtitle: preset.subtitle
                        ) {
                            store.navigate(to: preset.url)
                        }
                        .help("\(preset.title): \(preset.subtitle)")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 18) {
                    MediaNowPlayingSummary(
                        eyebrow: store.selectedProvider.rawValue,
                        title: store.pageTitle,
                        tint: BestBrowserBrand.secondary
                    )

                    Spacer(minLength: 12)

                    MediaNavigationButtons(
                        canGoBack: store.player.canGoBack,
                        canGoForward: store.player.canGoForward,
                        onBack: { store.player.goBack() },
                        onForward: { store.player.goForward() }
                    )
                    MediaVolumeControls(
                        isMuted: store.isMuted,
                        volume: store.volume,
                        activeTint: BestBrowserBrand.primary,
                        muteHelp: store.isMuted ? "Unmute music" : "Mute music",
                        volumeHelp: "Music volume",
                        onToggleMuted: { store.toggleMuted() },
                        onSetVolume: { store.setVolume($0) }
                    )
                }

                HStack(spacing: 10) {
                    MediaActionChip(title: "Browser", tint: BestBrowserBrand.secondary) {
                        onReturnToBrowser()
                    }

                    MediaActionChip(title: "Home", tint: BestBrowserBrand.primary) {
                        store.goHome()
                    }

                    MediaActionChip(title: "Reload", tint: BestBrowserBrand.primary) {
                        store.reload()
                    }

                    MediaActionChip(title: store.isPinnedToBottomBar ? "Hide Mini Player" : "Show Mini Player", tint: BestBrowserBrand.border) {
                        store.togglePinned()
                    }

                    MediaActionChip(title: "Open In Browser", tint: BestBrowserBrand.primary) {
                        BrowserViewModel.shared.openInCurrentTab(store.currentURL)
                    }

                    MediaActionChip(title: "Open In App", tint: BestBrowserBrand.border) {
                        guard let url = URL(string: store.currentURL) else { return }
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(BestBrowserBrand.darkCard)
        .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.6)).frame(height: 1), alignment: .bottom)
    }
}

struct MiniMusicPlayerStrip: View {
    @ObservedObject var store: MusicPlayerStore
    let onOpenMusic: () -> Void

    var body: some View {
        MiniMediaStripShell {
            Button(action: onOpenMusic) {
                HStack(spacing: 10) {
                    Image(systemName: store.selectedProvider.icon)
                        .foregroundColor(BestBrowserBrand.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.selectedProvider.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.secondary)
                        Text(store.pageTitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Open the full music surface")
        } controls: {
            HStack(spacing: 12) {
                MediaVolumeControls(
                    isMuted: store.isMuted,
                    volume: store.volume,
                    activeTint: BestBrowserBrand.primary,
                    muteHelp: store.isMuted ? "Unmute music" : "Mute music",
                    volumeHelp: "Music volume",
                    onToggleMuted: { store.toggleMuted() },
                    onSetVolume: { store.setVolume($0) }
                )
                .frame(width: 128)

                Menu {
                    Section("Provider") {
                        ForEach(MusicProvider.allCases) { provider in
                            Button(provider.rawValue) {
                                store.selectProvider(provider)
                            }
                        }
                    }
                } label: {
                    Label("Provider", systemImage: "music.note.house")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .menuStyle(.borderlessButton)
                .help("Switch music provider")

                Menu {
                    Section("Quick Picks") {
                        ForEach(store.presets) { preset in
                            Button(preset.title) {
                                store.navigate(to: preset.url)
                            }
                        }
                    }
                } label: {
                    Label("Quick Picks", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .menuStyle(.borderlessButton)
                .help("Open saved music destinations")

                MiniMediaIconButton(
                    systemName: "arrow.clockwise",
                    tint: BestBrowserBrand.primary,
                    helpText: "Reload the music player"
                ) {
                    store.reload()
                }

                MiniMediaIconButton(
                    systemName: "rectangle.inset.filled.and.person.filled",
                    tint: BestBrowserBrand.secondary,
                    helpText: "Open the full music surface"
                ) {
                    onOpenMusic()
                }
            }
        }
    }
}
