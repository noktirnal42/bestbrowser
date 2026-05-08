import SwiftUI
import WebKit

enum BrowserWebViewDefaults {
    static let compatibilityUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36"

    @MainActor
    static func makeConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.mediaTypesRequiringUserActionForPlayback = []

        if #available(macOS 11.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            config.preferences.javaScriptEnabled = true
        }

        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        if #available(macOS 26.0, *) {
            config.preferences.isElementFullscreenEnabled = true
        }

        return config
    }
}

struct WebViewWrapper: NSViewRepresentable {
    let url: String
    let tabId: UUID
    let viewModel: BrowserViewModel

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: BrowserWebViewDefaults.makeConfiguration())
        webView.customUserAgent = BrowserWebViewDefaults.compatibilityUserAgent
        let coordinator = context.coordinator
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        webView.allowsBackForwardNavigationGestures = true

        viewModel.privacyShield.attachTo(webView, pageURL: URL(string: url))

        coordinator.webView = webView
        viewModel.registerWebView(webView, for: tabId)

        if let url = URL(string: url) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.customUserAgent != BrowserWebViewDefaults.compatibilityUserAgent {
            nsView.customUserAgent = BrowserWebViewDefaults.compatibilityUserAgent
        }

        viewModel.privacyShield.attachTo(nsView, pageURL: URL(string: url))

        if let url = URL(string: url), nsView.url != url {
            nsView.load(URLRequest(url: url))
        }

        context.coordinator.webView = nsView
        viewModel.registerWebView(nsView, for: tabId)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebViewWrapper
        weak var webView: WKWebView?

        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.viewModel.privacyShield.attachTo(webView, pageURL: webView.url)
            parent.viewModel.updateUrl(webView.url?.absoluteString ?? "", for: parent.tabId)
            parent.viewModel.updateTitle(webView.title ?? "", for: parent.tabId)
            parent.viewModel.detectFavicon(for: parent.tabId, pageURL: webView.url, webView: webView)
            parent.viewModel.repairYouTubeLayoutIfNeeded(for: parent.tabId)
            updateNavigationState(webView)
            if parent.tabId == parent.viewModel.activeTabId {
                parent.viewModel.refreshCurrentMediaState()
            }

            Task { @MainActor in
                if let content = await parent.viewModel.content(for: parent.tabId),
                   let url = webView.url?.absoluteString {
                    await parent.viewModel.pageMemoryService.capturePage(
                        title: webView.title ?? url,
                        url: url,
                        content: content
                    )
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            updateNavigationState(webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if let url = navigationAction.request.url,
               parent.viewModel.completeAuthenticationIfNeeded(
                with: url,
                isMainFrame: navigationAction.targetFrame?.isMainFrame ?? true
               ) {
                return .cancel
            }

            DispatchQueue.main.async {
                self.parent.viewModel.privacyShield.attachTo(webView, pageURL: navigationAction.request.url)
                self.updateNavigationState(webView)
            }
            return .allow
        }

        func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse) async -> WKNavigationResponsePolicy {
            if !response.canShowMIMEType,
               let url = response.response.url {
                let suggestedFilename = response.response.suggestedFilename ?? url.lastPathComponent
                await MainActor.run {
                    _ = DownloadManager.shared.addDownload(from: url, suggestedFilename: suggestedFilename)
                }
                return .cancel
            }
            return .allow
        }

        private func updateNavigationState(_ webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.viewModel.canGoBack = webView.canGoBack
                self.parent.viewModel.canGoForward = webView.canGoForward
            }
        }
    }
}

struct FocusedPlayerWebViewWrapper: NSViewRepresentable {
    let url: String
    let tabId: UUID
    let viewModel: BrowserViewModel

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: BrowserWebViewDefaults.makeConfiguration())
        webView.customUserAgent = BrowserWebViewDefaults.compatibilityUserAgent
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        viewModel.privacyShield.attachTo(webView, pageURL: URL(string: url))

        context.coordinator.webView = webView
        viewModel.registerWebView(webView, for: tabId)

        if let url = URL(string: url) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.customUserAgent != BrowserWebViewDefaults.compatibilityUserAgent {
            nsView.customUserAgent = BrowserWebViewDefaults.compatibilityUserAgent
        }

        viewModel.privacyShield.attachTo(nsView, pageURL: URL(string: url))

        if let url = URL(string: url), nsView.url != url {
            nsView.load(URLRequest(url: url))
        }

        context.coordinator.webView = nsView
        viewModel.registerWebView(nsView, for: tabId)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: FocusedPlayerWebViewWrapper
        weak var webView: WKWebView?

        init(_ parent: FocusedPlayerWebViewWrapper) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.viewModel.privacyShield.attachTo(webView, pageURL: webView.url)
            updateNavigationState(webView)
            if parent.tabId == parent.viewModel.activeTabId {
                parent.viewModel.refreshCurrentMediaState()
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            updateNavigationState(webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if let url = navigationAction.request.url,
               parent.viewModel.completeAuthenticationIfNeeded(
                with: url,
                isMainFrame: navigationAction.targetFrame?.isMainFrame ?? true
               ) {
                return .cancel
            }

            DispatchQueue.main.async {
                self.parent.viewModel.privacyShield.attachTo(webView, pageURL: navigationAction.request.url)
                self.updateNavigationState(webView)
            }
            return .allow
        }

        private func updateNavigationState(_ webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.viewModel.canGoBack = webView.canGoBack
                self.parent.viewModel.canGoForward = webView.canGoForward
            }
        }
    }
}
