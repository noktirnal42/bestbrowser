import SwiftUI

struct BrowserCommandPaletteOverlayView: View {
    @ObservedObject var browserModel: BrowserViewModel
    @ObservedObject var shellStore: BrowserShellStore
    @ObservedObject var extensionHost: BrowserExtensionHost
    let commandCoordinator: BrowserCommandCoordinator

    var body: some View {
        if shellStore.showCommandPalette {
            CommandPaletteView(
                query: $shellStore.commandQuery,
                aiAvailable: AIClient.shared.isAvailable,
                extensionCommands: extensionCommands.map { ("Extension: \($0.name)", $0.icon) },
                onClose: { withAnimation(.spring()) { shellStore.dismissCommandPalette() } },
                onExecute: executePaletteAction
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .zIndex(100)
        }
    }

    private var extensionCommands: [BrowserExtension] {
        extensionHost.commandPaletteExtensions(for: URL(string: browserModel.url))
    }

    private func executePaletteAction(_ action: String) {
        if action.hasPrefix("Extension: "),
           let match = extensionCommands.first(where: { "Extension: \($0.name)" == action }) {
            extensionHost.run(match)
            shellStore.dismissCommandPalette()
            return
        }

        if let command = BrowserCommand(rawValue: action) {
            commandCoordinator.execute(command)
        }

        shellStore.dismissCommandPalette()
    }
}
