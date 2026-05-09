import WebKit

@MainActor
enum BrowserWebViewFactory {
    static func makeWebView(
        url: String,
        tabId: UUID,
        viewModel: BrowserViewModel,
        coordinator: NSObject & WKNavigationDelegate & WKUIDelegate
    ) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: BrowserWebViewDefaults.makeConfiguration())
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        webView.allowsBackForwardNavigationGestures = true

        if let coordinator = coordinator as? BrowserWebViewCoordinatorBase {
            coordinator.webView = webView
        }

        configure(webView, url: url, tabId: tabId, viewModel: viewModel)
        return webView
    }

    static func updateWebView(
        _ webView: WKWebView,
        url: String,
        tabId: UUID,
        viewModel: BrowserViewModel
    ) {
        configure(webView, url: url, tabId: tabId, viewModel: viewModel)
    }

    private static func configure(
        _ webView: WKWebView,
        url: String,
        tabId: UUID,
        viewModel: BrowserViewModel
    ) {
        if webView.customUserAgent != BrowserWebViewDefaults.compatibilityUserAgent {
            webView.customUserAgent = BrowserWebViewDefaults.compatibilityUserAgent
        }

        viewModel.privacyShield.attachTo(webView, pageURL: URL(string: url))
        viewModel.registerWebView(webView, for: tabId)

        if let targetURL = URL(string: url),
           webView.url != targetURL {
            webView.load(URLRequest(url: targetURL))
        }
    }
}
