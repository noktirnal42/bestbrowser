import WebKit

class BrowserWebViewCoordinatorBase: NSObject, WKNavigationDelegate, WKUIDelegate {
    let tabId: UUID
    let viewModel: BrowserViewModel
    weak var webView: WKWebView?

    init(tabId: UUID, viewModel: BrowserViewModel) {
        self.tabId = tabId
        self.viewModel = viewModel
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateNavigationState(webView)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if let url = navigationAction.request.url,
           viewModel.completeAuthenticationIfNeeded(
            with: url,
            isMainFrame: navigationAction.targetFrame?.isMainFrame ?? true
           ) {
            return .cancel
        }

        DispatchQueue.main.async {
            self.viewModel.privacyShield.attachTo(webView, pageURL: navigationAction.request.url)
            self.updateNavigationState(webView)
        }
        return .allow
    }

    func updateNavigationState(_ webView: WKWebView) {
        DispatchQueue.main.async {
            self.viewModel.canGoBack = webView.canGoBack
            self.viewModel.canGoForward = webView.canGoForward
        }
    }
}

final class BrowserTabWebViewCoordinator: BrowserWebViewCoordinatorBase {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewModel.privacyShield.attachTo(webView, pageURL: webView.url)
        viewModel.updateUrl(webView.url?.absoluteString ?? "", for: tabId)
        viewModel.updateTitle(webView.title ?? "", for: tabId)
        viewModel.detectFavicon(for: tabId, pageURL: webView.url, webView: webView)
        viewModel.repairYouTubeLayoutIfNeeded(for: tabId)
        updateNavigationState(webView)

        if tabId == viewModel.activeTabId {
            viewModel.refreshCurrentMediaState()
        }

        Task { @MainActor in
            if let content = await viewModel.content(for: tabId),
               let url = webView.url?.absoluteString {
                await viewModel.pageMemoryService.capturePage(
                    title: webView.title ?? url,
                    url: url,
                    content: content
                )
            }
        }
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
}

final class FocusedPlayerWebViewCoordinator: BrowserWebViewCoordinatorBase {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewModel.privacyShield.attachTo(webView, pageURL: webView.url)
        updateNavigationState(webView)

        if tabId == viewModel.activeTabId {
            viewModel.refreshCurrentMediaState()
        }
    }
}
