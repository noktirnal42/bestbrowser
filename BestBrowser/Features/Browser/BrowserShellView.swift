import SwiftUI

struct BrowserShellView: View {
    @StateObject private var browserModel = BrowserViewModel.shared
    @StateObject private var shellStore = BrowserShellStore.shared
    @StateObject private var compareService = CompareService.shared
    @StateObject private var extensionHost = BrowserExtensionHost.shared
    private let commandCoordinator = BrowserCommandCoordinator.shared

    var body: some View {
        ZStack {
            BrowserShellWorkspaceView(
                browserModel: browserModel,
                shellStore: shellStore,
                commandCoordinator: commandCoordinator
            )

            BrowserCommandPaletteOverlayView(
                browserModel: browserModel,
                shellStore: shellStore,
                extensionHost: extensionHost,
                commandCoordinator: commandCoordinator
            )
        }
        .browserShellPresentations(
            browserModel: browserModel,
            shellStore: shellStore,
            compareService: compareService
        )
        .onAppear {
            if !browserModel.url.isEmpty, browserModel.url != BrowserViewModel.newTabURL {
                Task {
                    try? await browserModel.storage.addHistory(
                        browserModel.url,
                        title: browserModel.tabs.first(where: { $0.id == browserModel.activeTabId })?.title ?? "Unknown"
                    )
                }
            }
        }
        .background(
            BrowserShellShortcutBridge(
                browserModel: browserModel,
                shellStore: shellStore,
                commandCoordinator: commandCoordinator
            )
        )
    }
}

#Preview {
    BrowserShellView()
}
