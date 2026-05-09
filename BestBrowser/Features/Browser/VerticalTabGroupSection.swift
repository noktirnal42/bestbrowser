import SwiftUI

struct VerticalTabGroupSection: View {
    let group: TabGroup
    let groupTabs: [BrowserTab]
    let allGroups: [TabGroup]
    let activeTabId: UUID?
    let tint: Color
    let onSelectTab: (UUID) -> Void
    let onCloseTab: (UUID) -> Void
    let onAssignTabToGroup: (UUID, UUID?) -> Void
    let onMoveTab: (UUID, UUID?, UUID?) -> Void
    let onToggleGroup: (UUID) -> Void
    let onRemoveGroup: (UUID) -> Void
    let onEditGroup: (TabGroup) -> Void
    let onReorderGroup: (UUID, UUID) -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button(action: { onToggleGroup(group.id) }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(tint)
                            .frame(width: 8, height: 8)
                        Text(group.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(groupTabs.count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.fog.opacity(0.72))
                        Image(systemName: group.isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(BestBrowserBrand.border)
                    }
                }
                .buttonStyle(.plain)
                .draggable(groupDragPayload(for: group))
                .dropDestination(
                    for: String.self,
                    action: { items, _ in
                        handleDrop(items: items, targetGroup: group.id, targetTab: nil)
                    },
                    isTargeted: { isTargeted in
                        self.isDropTargeted = isTargeted
                    }
                )

                Menu {
                    Button("Edit Group") {
                        onEditGroup(group)
                    }

                    Divider()

                    Button("Ungroup Tabs", role: .destructive) {
                        onRemoveGroup(group.id)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(BestBrowserBrand.border)
                }
                .menuStyle(.borderlessButton)
            }

            if !group.isCollapsed {
                VStack(spacing: 6) {
                    ForEach(groupTabs) { tab in
                        VerticalTabRow(
                            tab: tab,
                            isActive: tab.id == activeTabId,
                            tint: tint,
                            availableGroups: allGroups,
                            onSelect: { onSelectTab(tab.id) },
                            onClose: { onCloseTab(tab.id) },
                            onAssignToGroup: { targetGroupId in
                                onAssignTabToGroup(tab.id, targetGroupId)
                            },
                            onDropTabBefore: { draggedTabId in
                                onMoveTab(draggedTabId, group.id, tab.id)
                            }
                        )
                    }
                }
            }
        }
        .padding(8)
        .background(isDropTargeted ? tint.opacity(0.08) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isDropTargeted ? tint.opacity(0.7) : BestBrowserBrand.border.opacity(0.18),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 1.4 : 1, dash: isDropTargeted ? [5, 4] : [])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func handleDrop(items: [String], targetGroup: UUID?, targetTab: UUID?) -> Bool {
        guard let payload = items.first else { return false }

        if payload.hasPrefix("tab:"),
           let draggedTabId = UUID(uuidString: String(payload.dropFirst(4))) {
            onMoveTab(draggedTabId, targetGroup, targetTab)
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

    private func groupDragPayload(for group: TabGroup) -> String {
        "group:\(group.id.uuidString)"
    }
}
