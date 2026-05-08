import SwiftUI
import WebKit

@MainActor
final class PersistentWebPlayer: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var currentURL: String
    @Published var pageTitle: String
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var volume: Double = 1
    @Published var isMuted = false
    @Published var hasDetectedMedia = false

    let fallbackTitle: String
    let webView: WKWebView
    private let privacyShield: PrivacyShield?
    private let forcePrivacyProtection: Bool
    private let playbackControls = MediaPlaybackControlService.shared

    init(
        initialURL: String,
        fallbackTitle: String,
        privacyShield: PrivacyShield? = nil,
        forcePrivacyProtection: Bool = false
    ) {
        self.currentURL = initialURL
        self.pageTitle = fallbackTitle
        self.fallbackTitle = fallbackTitle
        self.privacyShield = privacyShield
        self.forcePrivacyProtection = forcePrivacyProtection
        self.webView = WKWebView(frame: .zero, configuration: BrowserWebViewDefaults.makeConfiguration())
        super.init()

        webView.customUserAgent = BrowserWebViewDefaults.compatibilityUserAgent
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        privacyShield?.attachTo(webView, pageURL: URL(string: initialURL), forceProtection: forcePrivacyProtection)

        if let target = URL(string: initialURL) {
            webView.load(URLRequest(url: target))
        }
    }

    func navigate(to url: String) {
        currentURL = url
        guard let target = URL(string: url) else { return }
        webView.load(URLRequest(url: target))
    }

    func reload() {
        webView.reload()
    }

    func setVolume(_ volume: Double) {
        self.volume = min(max(volume, 0), 1)
        playbackControls.applyState(
            volume: self.volume,
            muted: isMuted,
            to: webView,
            siteURL: currentURL
        )
    }

    func toggleMuted() {
        isMuted.toggle()
        playbackControls.applyState(
            volume: volume,
            muted: isMuted,
            to: webView,
            siteURL: currentURL
        )
    }

    func refreshPlaybackState() {
        playbackControls.refreshState(from: webView, siteURL: currentURL) { [weak self] volume, muted, hasMedia in
            guard let self else { return }
            self.volume = volume
            self.isMuted = muted
            self.hasDetectedMedia = hasMedia
        }
    }

    func attemptPlayback() {
        playbackControls.applyState(
            volume: volume,
            muted: isMuted,
            to: webView,
            siteURL: currentURL,
            attemptPlayback: true
        )
    }

    func goBack() {
        guard webView.canGoBack else { return }
        webView.goBack()
        syncNavigationState()
    }

    func goForward() {
        guard webView.canGoForward else { return }
        webView.goForward()
        syncNavigationState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        currentURL = webView.url?.absoluteString ?? currentURL
        pageTitle = webView.title ?? webView.url?.host ?? fallbackTitle
        syncNavigationState()
        refreshPlaybackState()
        attemptPlayback()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        syncNavigationState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        syncNavigationState()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        syncNavigationState()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        syncNavigationState()
    }

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

    private func syncNavigationState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

struct PersistentWebPlayerContainer: NSViewRepresentable {
    @ObservedObject var player: PersistentWebPlayer

    func makeNSView(context: Context) -> NSView {
        let container = NSView(frame: .zero)
        container.wantsLayer = true
        attachPlayer(to: container)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        attachPlayer(to: nsView)
    }

    private func attachPlayer(to container: NSView) {
        let webView = player.webView

        if webView.superview !== container {
            webView.removeFromSuperview()
            webView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                webView.topAnchor.constraint(equalTo: container.topAnchor),
                webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }
    }
}
