import SwiftUI

struct BrowserShellView: View {
    @StateObject private var browserModel = BrowserViewModel.shared
    @StateObject private var shellStore = BrowserShellStore.shared
    @StateObject private var compareService = CompareService.shared
    @StateObject private var extensionHost = BrowserExtensionHost.shared
    private let commandCoordinator = BrowserCommandCoordinator.shared

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                if shellStore.showSidebar && !shellStore.focusMode {
                    BrowserInspectorView()
                        .border(BestBrowserBrand.border, width: 1)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                if browserModel.verticalTabsEnabled && !shellStore.focusMode {
                    HStack(spacing: 0) {
                        VerticalTabRailView(
                            tabs: browserModel.tabs,
                            groups: browserModel.tabGroups,
                            activeTabId: browserModel.activeTabId,
                            onSelectTab: { browserModel.selectTab($0) },
                            onCloseTab: { browserModel.closeTab(id: $0) },
                            onNewTab: { browserModel.newTab() },
                            onToggleSidebar: { withAnimation(.spring()) { shellStore.toggleSidebar() } },
                            onToggleVerticalTabs: { browserModel.toggleVerticalTabs() },
                            onCreateGroup: { browserModel.createGroupFromCurrentTab() },
                            onAssignTabToGroup: { tabId, groupId in
                                browserModel.assignTab(tabId, to: groupId)
                            },
                            onMoveTab: { tabId, groupId, targetTabId in
                                browserModel.moveTab(tabId, toGroup: groupId, before: targetTabId)
                            },
                            onToggleGroup: { browserModel.toggleGroupCollapsed($0) },
                            onRemoveGroup: { browserModel.removeGroup($0) },
                            onEditGroup: { shellStore.editingGroup = $0 },
                            onReorderGroup: { draggedGroupId, targetGroupId in
                                browserModel.reorderGroup(draggedGroupId, before: targetGroupId)
                            }
                        )
                        .frame(width: 244)
                        .background(BestBrowserBrand.chrome)
                        .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.65)).frame(width: 1), alignment: .trailing)

                        BrowserMainColumnView(
                            browserModel: browserModel,
                            shellStore: shellStore,
                            commandCoordinator: commandCoordinator
                        )
                    }
                } else {
                    BrowserMainColumnView(
                        browserModel: browserModel,
                        shellStore: shellStore,
                        commandCoordinator: commandCoordinator
                    )
                }
            }

            if shellStore.showCommandPalette {
                CommandPaletteView(
                    query: $shellStore.commandQuery,
                    aiAvailable: AIClient.shared.isAvailable,
                    extensionCommands: extensionHost.commandPaletteExtensions(for: URL(string: browserModel.url)).map {
                        ("Extension: \($0.name)", $0.icon)
                    },
                    onClose: { withAnimation(.spring()) { shellStore.dismissCommandPalette() } },
                    onExecute: { action in
                        if action.hasPrefix("Extension: "),
                           let match = extensionHost.commandPaletteExtensions(for: URL(string: browserModel.url)).first(where: {
                               "Extension: \($0.name)" == action
                           }) {
                            extensionHost.run(match)
                            shellStore.dismissCommandPalette()
                            return
                        }
                        if let command = BrowserCommand(rawValue: action) {
                            commandCoordinator.execute(command)
                        }
                        shellStore.dismissCommandPalette()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(100)
            }
        }
        .sheet(isPresented: $shellStore.showingSettings) {
            SettingsWindow()
        }
        .sheet(isPresented: $shellStore.showingDownloads) {
            DownloadManagerView()
        }
        .sheet(item: $shellStore.readingModePayload) { payload in
            ReadingModeView(title: payload.title, content: payload.content, url: payload.url)
        }
        .sheet(item: $shellStore.comparePresentation) { presentation in
            CompareTabsView(presentation: presentation, recentSessions: compareService.recentSessions)
        }
        .sheet(isPresented: $shellStore.splitPickerVisible) {
            SplitTabPickerSheet(
                tabs: browserModel.availableSplitCandidates(),
                onSelect: { tab in
                    browserModel.splitPrimaryTabId = shellStore.splitPickerPrimaryTabId ?? browserModel.activeTabId
                    browserModel.setSplitTab(tab.id)
                    shellStore.dismissSplitPicker()
                },
                onCancel: { shellStore.dismissSplitPicker() }
            )
        }
        .sheet(item: $shellStore.editingGroup) { group in
            EditTabGroupSheet(
                group: group,
                onSave: { name, colorKey in
                    browserModel.updateGroup(group.id, name: name, colorKey: colorKey)
                    shellStore.editingGroup = nil
                },
                onDelete: {
                    browserModel.removeGroup(group.id)
                    shellStore.editingGroup = nil
                },
                onCancel: {
                    shellStore.editingGroup = nil
                }
            )
        }
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
            Group {
                Button("") { withAnimation(.spring()) { shellStore.presentCommandPalette() } }
                    .keyboardShortcut("k", modifiers: .command).opacity(0)
                Button("") { commandCoordinator.execute(BrowserCommand.toggleFocusMode) }
                    .keyboardShortcut("f", modifiers: [.command, .shift]).opacity(0)
                Button("") { browserModel.refresh() }
                    .keyboardShortcut("r", modifiers: .command).opacity(0)
                Button("") { commandCoordinator.execute(BrowserCommand.newTab) }
                    .keyboardShortcut("t", modifiers: .command).opacity(0)
                Button("") { commandCoordinator.execute(BrowserCommand.closeTab) }
                    .keyboardShortcut("w", modifiers: .command).opacity(0)
                Button("") { commandCoordinator.execute(BrowserCommand.reopenClosedTab) }
                    .keyboardShortcut("t", modifiers: [.command, .shift]).opacity(0)
                Button("") { commandCoordinator.execute(BrowserCommand.toggleSplitView) }
                    .keyboardShortcut("\\", modifiers: [.command, .shift]).opacity(0)
                Button("") { commandCoordinator.execute(BrowserCommand.toggleVerticalTabs) }
                    .keyboardShortcut("v", modifiers: [.command, .shift]).opacity(0)
                Button("") { commandCoordinator.execute(BrowserCommand.groupCurrentTab) }
                    .keyboardShortcut("g", modifiers: [.command, .shift]).opacity(0)
            }
        )
    }
}

#Preview {
    BrowserShellView()
}
