import SwiftUI

struct BrowserShellShortcutBridge: View {
    @ObservedObject var browserModel: BrowserViewModel
    @ObservedObject var shellStore: BrowserShellStore
    let commandCoordinator: BrowserCommandCoordinator

    var body: some View {
        Group {
            HiddenShortcutButton(key: "k", modifiers: .command) {
                withAnimation(.spring()) { shellStore.presentCommandPalette() }
            }
            HiddenShortcutButton(key: "f", modifiers: [.command, .shift]) {
                commandCoordinator.execute(BrowserCommand.toggleFocusMode)
            }
            HiddenShortcutButton(key: "r", modifiers: .command) {
                browserModel.refresh()
            }
            HiddenShortcutButton(key: "t", modifiers: .command) {
                commandCoordinator.execute(BrowserCommand.newTab)
            }
            HiddenShortcutButton(key: "w", modifiers: .command) {
                commandCoordinator.execute(BrowserCommand.closeTab)
            }
            HiddenShortcutButton(key: "t", modifiers: [.command, .shift]) {
                commandCoordinator.execute(BrowserCommand.reopenClosedTab)
            }
            HiddenShortcutButton(key: "\\", modifiers: [.command, .shift]) {
                commandCoordinator.execute(BrowserCommand.toggleSplitView)
            }
            HiddenShortcutButton(key: "v", modifiers: [.command, .shift]) {
                commandCoordinator.execute(BrowserCommand.toggleVerticalTabs)
            }
            HiddenShortcutButton(key: "g", modifiers: [.command, .shift]) {
                commandCoordinator.execute(BrowserCommand.groupCurrentTab)
            }
        }
    }
}

private struct HiddenShortcutButton: View {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void

    var body: some View {
        Button("", action: action)
            .keyboardShortcut(key, modifiers: modifiers)
            .opacity(0)
    }
}
