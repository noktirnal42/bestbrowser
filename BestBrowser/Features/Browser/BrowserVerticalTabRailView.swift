import SwiftUI

struct VerticalTabRailView: View {
    let tabs: [BrowserTab]
    let groups: [TabGroup]
    let activeTabId: UUID?
    let onSelectTab: (UUID) -> Void
    let onCloseTab: (UUID) -> Void
    let onNewTab: () -> Void
    let onToggleSidebar: () -> Void
    let onToggleVerticalTabs: () -> Void
    let onCreateGroup: () -> Void
    let onAssignTabToGroup: (UUID, UUID?) -> Void
    let onMoveTab: (UUID, UUID?, UUID?) -> Void
    let onToggleGroup: (UUID) -> Void
    let onRemoveGroup: (UUID) -> Void
    let onEditGroup: (TabGroup) -> Void
    let onReorderGroup: (UUID, UUID) -> Void
    @State private var ungroupedDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tab Rail")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.secondary)
                    Text("\(tabs.count) open")
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.72))
                }

                Spacer()

                HStack(spacing: 6) {
                    railIconButton(icon: "sidebar.left", action: onToggleSidebar)
                    railIconButton(icon: "plus", action: onNewTab)
                    railIconButton(icon: "square.stack.3d.up.fill", action: onCreateGroup)
                    railIconButton(icon: "rectangle.tophalf.inset.filled", action: onToggleVerticalTabs)
                }
            }
            .padding(12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !ungroupedTabs.isEmpty {
                        railSectionLabel("Ungrouped")
                        VStack(spacing: 6) {
                            ForEach(ungroupedTabs) { tab in
                                VerticalTabRow(
                                    tab: tab,
                                    isActive: tab.id == activeTabId,
                                    tint: BestBrowserBrand.border,
                                    availableGroups: groups,
                                    onSelect: { onSelectTab(tab.id) },
                                    onClose: { onCloseTab(tab.id) },
                                    onAssignToGroup: { groupId in
                                        onAssignTabToGroup(tab.id, groupId)
                                    },
                                    onDropTabBefore: { draggedTabId in
                                        onMoveTab(draggedTabId, nil, tab.id)
                                    }
                                )
                            }
                        }
                        .padding(8)
                        .background(ungroupedDropTargeted ? BestBrowserBrand.primary.opacity(0.08) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    ungroupedDropTargeted ? BestBrowserBrand.primary.opacity(0.55) : BestBrowserBrand.border.opacity(0.2),
                                    style: StrokeStyle(lineWidth: ungroupedDropTargeted ? 1.4 : 1, dash: ungroupedDropTargeted ? [5, 4] : [])
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .dropDestination(
                            for: String.self,
                            action: { items, _ in
                                handleDrop(items: items, targetGroup: nil, targetTab: nil)
                            },
                            isTargeted: { isTargeted in
                                ungroupedDropTargeted = isTargeted
                            }
                        )
                    }

                    ForEach(groups) { group in
                        let groupTabs = tabs.filter { $0.groupId == group.id }
                        if !groupTabs.isEmpty {
                            VerticalTabGroupSection(
                                group: group,
                                groupTabs: groupTabs,
                                allGroups: groups,
                                activeTabId: activeTabId,
                                tint: BrowserTabGroupPalette.color(for: group.colorKey),
                                onSelectTab: onSelectTab,
                                onCloseTab: onCloseTab,
                                onAssignTabToGroup: onAssignTabToGroup,
                                onMoveTab: onMoveTab,
                                onToggleGroup: onToggleGroup,
                                onRemoveGroup: onRemoveGroup,
                                onEditGroup: onEditGroup,
                                onReorderGroup: onReorderGroup
                            )
                        }
                    }
                }
                .padding(12)
            }
        }
    }

    private var ungroupedTabs: [BrowserTab] {
        tabs.filter { $0.groupId == nil }
    }

    @ViewBuilder
    private func railSectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(BestBrowserBrand.fog.opacity(0.55))
    }

    @ViewBuilder
    private func railIconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(BestBrowserBrand.primary)
                .padding(8)
                .background(BestBrowserBrand.raisedCard)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func handleDrop(items: [String], targetGroup: UUID?, targetTab: UUID?) -> Bool {
        guard let payload = items.first else { return false }

        if payload.hasPrefix("tab:"),
           let draggedTabId = UUID(uuidString: String(payload.dropFirst(4))) {
            if let targetTab {
                onMoveTab(draggedTabId, targetGroup, targetTab)
            } else {
                onMoveTab(draggedTabId, targetGroup, nil)
            }
            return true
        }

        if payload.hasPrefix("group:"),
           let targetGroup,
           let draggedGroupId = UUID(uuidString: String(payload.dropFirst(6))) {
            onReorderGroup(draggedGroupId, targetGroup)
            return true
        }

        return false
    }
}
