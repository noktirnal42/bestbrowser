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
