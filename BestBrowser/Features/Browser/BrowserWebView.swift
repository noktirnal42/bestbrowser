import SwiftUI
import WebKit

struct WebViewWrapper: NSViewRepresentable {
    let url: String
    let tabId: UUID
    let viewModel: BrowserViewModel

    func makeNSView(context: Context) -> WKWebView {
        return BrowserWebViewFactory.makeWebView(
            url: url,
            tabId: tabId,
            viewModel: viewModel,
            coordinator: context.coordinator
        )
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        BrowserWebViewFactory.updateWebView(nsView, url: url, tabId: tabId, viewModel: viewModel)
        context.coordinator.webView = nsView
    }

    func makeCoordinator() -> BrowserTabWebViewCoordinator {
        BrowserTabWebViewCoordinator(tabId: tabId, viewModel: viewModel)
    }
}

struct FocusedPlayerWebViewWrapper: NSViewRepresentable {
    let url: String
    let tabId: UUID
    let viewModel: BrowserViewModel

    func makeNSView(context: Context) -> WKWebView {
        return BrowserWebViewFactory.makeWebView(
            url: url,
            tabId: tabId,
            viewModel: viewModel,
            coordinator: context.coordinator
        )
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        BrowserWebViewFactory.updateWebView(nsView, url: url, tabId: tabId, viewModel: viewModel)
        context.coordinator.webView = nsView
    }

    func makeCoordinator() -> FocusedPlayerWebViewCoordinator {
        FocusedPlayerWebViewCoordinator(tabId: tabId, viewModel: viewModel)
    }
}
