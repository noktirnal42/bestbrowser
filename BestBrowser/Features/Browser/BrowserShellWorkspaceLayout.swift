import SwiftUI

struct BrowserShellWorkspaceView: View {
    @ObservedObject var browserModel: BrowserViewModel
    @ObservedObject var shellStore: BrowserShellStore
    let commandCoordinator: BrowserCommandCoordinator

    var body: some View {
        HStack(spacing: 0) {
            if shellStore.showSidebar && !shellStore.focusMode {
                BrowserInspectorView()
                    .border(BestBrowserBrand.border, width: 1)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            if browserModel.verticalTabsEnabled && !shellStore.focusMode {
                VerticalTabsWorkspaceLayout(
                    browserModel: browserModel,
                    shellStore: shellStore,
                    commandCoordinator: commandCoordinator
                )
            } else {
                BrowserMainColumnView(
                    browserModel: browserModel,
                    shellStore: shellStore,
                    commandCoordinator: commandCoordinator
                )
            }
        }
    }
}

private struct VerticalTabsWorkspaceLayout: View {
    @ObservedObject var browserModel: BrowserViewModel
    @ObservedObject var shellStore: BrowserShellStore
    let commandCoordinator: BrowserCommandCoordinator

    var body: some View {
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
    }
}
