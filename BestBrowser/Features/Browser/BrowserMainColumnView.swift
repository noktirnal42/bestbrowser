import SwiftUI

struct BrowserMainColumnView: View {
    @ObservedObject var browserModel: BrowserViewModel
    @ObservedObject var shellStore: BrowserShellStore
    let commandCoordinator: BrowserCommandCoordinator
    @StateObject private var extensionHost = BrowserExtensionHost.shared
    @StateObject private var videoStore = VideoPlayerStore.shared

    var body: some View {
        VStack(spacing: 0) {
            MainColumnTopChrome(
                browserModel: browserModel,
                shellStore: shellStore,
                commandCoordinator: commandCoordinator,
                extensionHost: extensionHost,
                videoStore: videoStore
            )

            MainColumnContentSurface(browserModel: browserModel)

            FocusModeBanner(shellStore: shellStore)
        }
    }
}
