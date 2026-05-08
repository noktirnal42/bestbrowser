import SwiftUI
import AppKit
import Combine
import WebKit

struct VideoPreset: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let url: String
}

enum VideoProvider: String, CaseIterable, Identifiable {
    case youtube = "YouTube"
    case twitch = "Twitch"
    case primeVideo = "Prime Video"
    case max = "Max"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .twitch: return "bubble.left.and.text.bubble.right.fill"
        case .primeVideo: return "film.stack.fill"
        case .max: return "tv.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .youtube:
            return "Subscriptions, long-form streams, and ambient background video."
        case .twitch:
            return "Live creators, esports, and chat-heavy streams."
        case .primeVideo:
            return "Prime Video in a dedicated always-open pane."
        case .max:
            return "HBO and Max for premium long-form viewing while you browse."
        }
    }

    var homeURL: String {
        switch self {
        case .youtube: return "https://www.youtube.com/feed/subscriptions"
        case .twitch: return "https://www.twitch.tv/"
        case .primeVideo: return "https://www.primevideo.com/"
        case .max: return "https://play.max.com/"
        }
    }

    var presets: [VideoPreset] {
        switch self {
        case .youtube:
            return [
                VideoPreset(id: "yt-subs", title: "Subscriptions", subtitle: "Your regular background feed", url: "https://www.youtube.com/feed/subscriptions"),
                VideoPreset(id: "yt-live", title: "Live", subtitle: "Jump into streams and live coverage", url: "https://www.youtube.com/live"),
                VideoPreset(id: "yt-home", title: "Home", subtitle: "Recommendations and queue surfing", url: "https://www.youtube.com/")
            ]
        case .twitch:
            return [
                VideoPreset(id: "tw-following", title: "Following", subtitle: "Live channels you already follow", url: "https://www.twitch.tv/directory/following/live"),
                VideoPreset(id: "tw-browse", title: "Browse", subtitle: "Find a category or creator", url: "https://www.twitch.tv/directory"),
                VideoPreset(id: "tw-esports", title: "Esports", subtitle: "Competitive streams and tournaments", url: "https://www.twitch.tv/directory/category/esports")
            ]
        case .primeVideo:
            return [
                VideoPreset(id: "prime-home", title: "Home", subtitle: "Return to your Prime Video front page", url: "https://www.primevideo.com/"),
                VideoPreset(id: "prime-store", title: "Store", subtitle: "Browse the main Prime catalog", url: "https://www.primevideo.com/storefront/home"),
                VideoPreset(id: "prime-my-stuff", title: "My Stuff", subtitle: "Watchlist and saved items", url: "https://www.primevideo.com/storefront/home/mystuff")
            ]
        case .max:
            return [
                VideoPreset(id: "max-home", title: "Home", subtitle: "Resume and recommendations", url: "https://play.max.com/"),
                VideoPreset(id: "max-series", title: "Series", subtitle: "Jump into show browsing", url: "https://play.max.com/shows"),
                VideoPreset(id: "max-movies", title: "Movies", subtitle: "Premium movie catalog", url: "https://play.max.com/movies")
            ]
        }
    }
}

enum VideoPanePosition: String, CaseIterable, Identifiable {
    case topRight
    case bottomRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topRight: return "Top Right"
        case .bottomRight: return "Bottom Right"
        }
    }

    var alignment: Alignment {
        switch self {
        case .topRight: return .topTrailing
        case .bottomRight: return .bottomTrailing
        }
    }
}

enum VideoPaneSize: String, CaseIterable, Identifiable {
    case compact
    case standard
    case large

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var width: CGFloat {
        switch self {
        case .compact: return 320
        case .standard: return 420
        case .large: return 520
        }
    }

    var height: CGFloat {
        switch self {
        case .compact: return 180
        case .standard: return 236
        case .large: return 292
        }
    }
}

@MainActor
final class VideoPlayerStore: ObservableObject {
    static let shared = VideoPlayerStore()

    @Published var selectedProvider: VideoProvider
    @Published var isPinnedPaneVisible = true
    @Published var isPinnedPaneCollapsed: Bool
    @Published var panePosition: VideoPanePosition
    @Published var paneSize: VideoPaneSize
    @Published var paneOffsetX: Double
    @Published var paneOffsetY: Double

    let player: PersistentWebPlayer

    private let providerKey = "bestbrowser.video.provider"
    private let pinnedKey = "bestbrowser.video.pinned"
    private let collapsedKey = "bestbrowser.video.collapsed"
    private let positionKey = "bestbrowser.video.position"
    private let sizeKey = "bestbrowser.video.size"
    private let offsetXKey = "bestbrowser.video.offsetX"
    private let offsetYKey = "bestbrowser.video.offsetY"
    private let urlKeyPrefix = "bestbrowser.video.url."
    private let siteCompatibility = SiteCompatibilityService.shared
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let raw = UserDefaults.standard.string(forKey: providerKey)
        let provider = VideoProvider(rawValue: raw ?? "") ?? .youtube
        self.selectedProvider = provider
        let initialURL = UserDefaults.standard.string(forKey: "\(urlKeyPrefix)\(provider.rawValue)") ?? provider.homeURL
        self.player = PersistentWebPlayer(
            initialURL: initialURL,
            fallbackTitle: "Video",
            privacyShield: PrivacyShield.shared,
            forcePrivacyProtection: true
        )
        self.isPinnedPaneVisible = UserDefaults.standard.object(forKey: pinnedKey) as? Bool ?? true
        self.isPinnedPaneCollapsed = UserDefaults.standard.object(forKey: collapsedKey) as? Bool ?? false
        self.panePosition = VideoPanePosition(rawValue: UserDefaults.standard.string(forKey: positionKey) ?? "") ?? .bottomRight
        self.paneSize = VideoPaneSize(rawValue: UserDefaults.standard.string(forKey: sizeKey) ?? "") ?? .standard
        self.paneOffsetX = UserDefaults.standard.double(forKey: offsetXKey)
        self.paneOffsetY = UserDefaults.standard.double(forKey: offsetYKey)

        sanitizePersistedPaneOffset()

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

    private func sanitizePersistedPaneOffset() {
        let maxReasonableX = max(Double(paneSize.width), 420)
        let maxReasonableY = 260.0

        if abs(paneOffsetX) > maxReasonableX || abs(paneOffsetY) > maxReasonableY {
            resetPaneOffset()
        }
    }

    func selectProvider(_ provider: VideoProvider) {
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: providerKey)
        player.navigate(to: UserDefaults.standard.string(forKey: "\(urlKeyPrefix)\(provider.rawValue)") ?? provider.homeURL)
    }

    func navigate(to url: String) {
        player.navigate(to: url)
    }

    func reload() {
        player.reload()
    }

    func goHome() {
        player.navigate(to: selectedProvider.homeURL)
    }

    func togglePinned() {
        isPinnedPaneVisible.toggle()
        UserDefaults.standard.set(isPinnedPaneVisible, forKey: pinnedKey)
    }

    func setPinnedPaneVisible(_ visible: Bool) {
        isPinnedPaneVisible = visible
        UserDefaults.standard.set(visible, forKey: pinnedKey)
    }

    func togglePinnedPaneCollapsed() {
        isPinnedPaneCollapsed.toggle()
        UserDefaults.standard.set(isPinnedPaneCollapsed, forKey: collapsedKey)
    }

    func setPanePosition(_ position: VideoPanePosition) {
        panePosition = position
        UserDefaults.standard.set(position.rawValue, forKey: positionKey)
    }

    func setPaneSize(_ size: VideoPaneSize) {
        paneSize = size
        UserDefaults.standard.set(size.rawValue, forKey: sizeKey)
    }

    func setPaneOffset(x: Double, y: Double) {
        paneOffsetX = x
        paneOffsetY = y
        UserDefaults.standard.set(x, forKey: offsetXKey)
        UserDefaults.standard.set(y, forKey: offsetYKey)
    }

    func resetPaneOffset() {
        setPaneOffset(x: 0, y: 0)
    }

    var currentFloatingPaneWidth: CGFloat {
        paneSize.width
    }

    var currentFloatingPaneHeight: CGFloat {
        let headerHeight: CGFloat = 52
        return isPinnedPaneCollapsed ? headerHeight : (headerHeight + paneSize.height)
    }

    func clampPaneOffset(
        in containerSize: CGSize,
        trailingPadding: CGFloat = 24,
        topPadding: CGFloat = 24,
        bottomPadding: CGFloat
    ) {
        guard containerSize.width > 0, containerSize.height > 0 else { return }

        let paneWidth = currentFloatingPaneWidth
        let paneHeight = currentFloatingPaneHeight
        let visibleMargin: CGFloat = 12

        let baseOriginX = containerSize.width - trailingPadding - paneWidth
        let baseOriginY: CGFloat = {
            switch panePosition {
            case .topRight:
                return topPadding
            case .bottomRight:
                return containerSize.height - bottomPadding - paneHeight
            }
        }()

        let unclampedOriginX = baseOriginX + paneOffsetX
        let unclampedOriginY = baseOriginY + paneOffsetY

        let minOriginX = visibleMargin
        let maxOriginX = max(visibleMargin, containerSize.width - paneWidth - visibleMargin)
        let minOriginY = visibleMargin
        let maxOriginY = max(visibleMargin, containerSize.height - paneHeight - visibleMargin)

        let clampedOriginX = min(max(unclampedOriginX, minOriginX), maxOriginX)
        let clampedOriginY = min(max(unclampedOriginY, minOriginY), maxOriginY)

        let clampedOffsetX = clampedOriginX - baseOriginX
        let clampedOffsetY = clampedOriginY - baseOriginY

        if abs(clampedOffsetX - paneOffsetX) > 0.5 || abs(clampedOffsetY - paneOffsetY) > 0.5 {
            setPaneOffset(x: clampedOffsetX, y: clampedOffsetY)
        }
    }

    var presets: [VideoPreset] {
        selectedProvider.presets
    }

    var currentURL: String { player.currentURL }
    var pageTitle: String { player.pageTitle }
    var volume: Double { player.volume }
    var isMuted: Bool { player.isMuted }
    var usesFocusedFloatingPlayer: Bool {
        selectedProvider == .youtube && siteCompatibility.isYouTubeWatchURL(currentURL)
    }
    var floatingPlayerURL: String {
        guard usesFocusedFloatingPlayer,
              let videoId = siteCompatibility.youTubeVideoID(from: currentURL) else {
            return currentURL
        }

        let params = [
            "autoplay=1",
            "playsinline=1",
            "rel=0",
            "modestbranding=1",
            "fs=1"
        ].joined(separator: "&")

        return "https://www.youtube.com/embed/\(videoId)?\(params)"
    }

    func setVolume(_ volume: Double) {
        player.setVolume(volume)
    }

    func toggleMuted() {
        player.toggleMuted()
    }
}

struct VideoPlayerView: View {
    @StateObject private var store = VideoPlayerStore.shared
    let onReturnToBrowser: () -> Void
    private let providerColumns = [GridItem(.adaptive(minimum: 240), spacing: 12)]
    private let presetColumns = [GridItem(.adaptive(minimum: 220), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            header
            PersistentWebPlayerContainer(player: store.player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BestBrowserBrand.darkBg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            MediaSurfaceHero(
                title: "Video Pane",
                description: "Keep a dedicated video service open while you browse. This pane is designed for YouTube, Twitch, Prime Video, and Max so your stream stays nearby without taking over the browser."
            )

            LazyVGrid(columns: providerColumns, alignment: .leading, spacing: 12) {
                ForEach(VideoProvider.allCases) { provider in
                    MediaProviderCard(
                        title: provider.rawValue,
                        subtitle: provider.subtitle,
                        icon: provider.icon,
                        isSelected: provider == store.selectedProvider,
                        activeTint: BestBrowserBrand.secondary
                    ) {
                        store.selectProvider(provider)
                    }
                    .help("Switch video provider to \(provider.rawValue)")
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
                        muteHelp: store.isMuted ? "Unmute video" : "Mute video",
                        volumeHelp: "Video volume",
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

                    MediaActionChip(title: store.isPinnedPaneVisible ? "Hide Floating Pane" : "Show Floating Pane", tint: BestBrowserBrand.border) {
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

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Floating Pane Position")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)

                        Picker("Pane Position", selection: Binding(
                            get: { store.panePosition },
                            set: { store.setPanePosition($0) }
                        )) {
                            ForEach(VideoPanePosition.allCases) { position in
                                Text(position.title).tag(position)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 240)
                        .help("Choose where the floating video pane anchors")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Floating Pane Size")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)

                        Picker("Pane Size", selection: Binding(
                            get: { store.paneSize },
                            set: { store.setPaneSize($0) }
                        )) {
                            ForEach(VideoPaneSize.allCases) { size in
                                Text(size.title).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 280)
                        .help("Choose the floating video pane size")
                    }

                    Spacer()
                }
            }
        }
        .padding(24)
        .background(BestBrowserBrand.darkCard)
        .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.6)).frame(height: 1), alignment: .bottom)
    }
}

struct FloatingVideoPane: View {
    @ObservedObject var store: VideoPlayerStore
    let onOpenVideo: () -> Void
    @State private var dragStartX: Double = 0
    @State private var dragStartY: Double = 0
    @State private var liveDragX: Double = 0
    @State private var liveDragY: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: onOpenVideo) {
                    HStack(spacing: 8) {
                        Image(systemName: store.selectedProvider.icon)
                            .foregroundColor(BestBrowserBrand.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.selectedProvider.rawValue)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(BestBrowserBrand.secondary)
                            Text(store.pageTitle)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .help("Open the full video surface")

                Spacer()

                Menu {
                    ForEach(store.presets.prefix(3)) { preset in
                        Button(preset.title) {
                            store.navigate(to: preset.url)
                        }
                    }
                } label: {
                    Image(systemName: "sparkles.tv")
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .menuStyle(.borderlessButton)
                .help("Quick video destinations")

                Button {
                    store.resetPaneOffset()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right.circle")
                        .foregroundColor(BestBrowserBrand.border)
                }
                .buttonStyle(.plain)
                .help("Reset pane position")

                Button {
                    store.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .buttonStyle(.plain)
                .help("Reload video pane")

                Button {
                    store.togglePinnedPaneCollapsed()
                } label: {
                    Image(systemName: store.isPinnedPaneCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .buttonStyle(.plain)
                .help(store.isPinnedPaneCollapsed ? "Expand video pane" : "Collapse video pane")

                Button {
                    store.toggleMuted()
                } label: {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(store.isMuted ? BestBrowserBrand.warning : BestBrowserBrand.primary)
                }
                .buttonStyle(.plain)
                .help(store.isMuted ? "Unmute video" : "Mute video")

                Slider(
                    value: Binding(
                        get: { store.volume },
                        set: { store.setVolume($0) }
                    ),
                    in: 0...1
                )
                .frame(width: 88)
                .help("Video volume")

                Button {
                    onOpenVideo()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .buttonStyle(.plain)
                .help("Open video surface")

                Button {
                    store.togglePinned()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(BestBrowserBrand.border)
                }
                .buttonStyle(.plain)
                .help("Hide video pane")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(BestBrowserBrand.chrome.opacity(0.98))
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        liveDragX = value.translation.width
                        liveDragY = value.translation.height
                    }
                    .onEnded { value in
                        store.setPaneOffset(
                            x: dragStartX + value.translation.width,
                            y: dragStartY + value.translation.height
                        )
                        dragStartX = store.paneOffsetX
                        dragStartY = store.paneOffsetY
                        liveDragX = 0
                        liveDragY = 0
                    }
            )

            if !store.isPinnedPaneCollapsed {
                Group {
                    if store.usesFocusedFloatingPlayer {
                        FocusedFloatingVideoPaneWebView(
                            url: store.floatingPlayerURL,
                            volume: store.volume,
                            isMuted: store.isMuted
                        )
                    } else {
                        PersistentWebPlayerContainer(player: store.player)
                    }
                }
                .frame(width: store.paneSize.width, height: store.paneSize.height)
                .background(Color.black)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(width: store.paneSize.width)
        .onAppear {
            dragStartX = store.paneOffsetX
            dragStartY = store.paneOffsetY
        }
        .offset(x: liveDragX, y: liveDragY)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(BestBrowserBrand.border.opacity(0.85), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 24, y: 14)
    }
}

private struct FocusedFloatingVideoPaneWebView: NSViewRepresentable {
    let url: String
    let volume: Double
    let isMuted: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: BrowserWebViewDefaults.makeConfiguration())
        webView.customUserAgent = BrowserWebViewDefaults.compatibilityUserAgent
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        PrivacyShield.shared.attachTo(webView, pageURL: URL(string: url), forceProtection: true)

        if let target = URL(string: url) {
            webView.load(URLRequest(url: target))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.customUserAgent != BrowserWebViewDefaults.compatibilityUserAgent {
            nsView.customUserAgent = BrowserWebViewDefaults.compatibilityUserAgent
        }

        if let target = URL(string: url), nsView.url != target {
            nsView.load(URLRequest(url: target))
        }

        MediaPlaybackControlService.shared.applyState(
            volume: volume,
            muted: isMuted,
            to: nsView,
            siteURL: url,
            attemptPlayback: true
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
