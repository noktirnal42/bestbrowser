import SwiftUI

private struct BrowserShellPresentationModifier: ViewModifier {
    @ObservedObject var browserModel: BrowserViewModel
    @ObservedObject var shellStore: BrowserShellStore
    @ObservedObject var compareService: CompareService

    func body(content: Content) -> some View {
        content
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
    }
}

extension View {
    func browserShellPresentations(
        browserModel: BrowserViewModel,
        shellStore: BrowserShellStore,
        compareService: CompareService
    ) -> some View {
        modifier(
            BrowserShellPresentationModifier(
                browserModel: browserModel,
                shellStore: shellStore,
                compareService: compareService
            )
        )
    }
}
