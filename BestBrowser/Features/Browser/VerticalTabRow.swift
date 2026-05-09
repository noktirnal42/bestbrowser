import SwiftUI

struct VerticalTabRow: View {
    let tab: BrowserTab
    let isActive: Bool
    let tint: Color
    let availableGroups: [TabGroup]
    let onSelect: () -> Void
    let onClose: () -> Void
    let onAssignToGroup: (UUID?) -> Void
    let onDropTabBefore: (UUID) -> Void

    @State private var isDropTargeted = false

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isActive ? tint : tint.opacity(0.35))
                .frame(width: 4, height: 26)

            FaviconView(faviconURL: tab.favicon, isActive: isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title.isEmpty ? "Untitled Tab" : tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isActive ? .white : BestBrowserBrand.fog.opacity(0.9))
                    .lineLimit(1)

                Text(tab.url)
                    .font(.system(size: 10))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Menu {
                if !availableGroups.isEmpty {
                    ForEach(availableGroups) { group in
                        Button(group.name) {
                            onAssignToGroup(group.id)
                        }
                    }

                    Divider()
                }

                Button("Remove from Group") {
                    onAssignToGroup(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 12))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .menuStyle(.borderlessButton)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isDropTargeted
                ? tint.opacity(0.12)
                : (isActive ? BestBrowserBrand.raisedCard : BestBrowserBrand.cardBackground.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isDropTargeted
                        ? tint.opacity(0.78)
                        : (isActive ? tint.opacity(0.45) : BestBrowserBrand.border.opacity(0.42)),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 1.5 : 1, dash: isDropTargeted ? [5, 4] : [])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onSelect)
        .draggable("tab:\(tab.id.uuidString)")
        .dropDestination(
            for: String.self,
            action: { items, _ in
                guard let payload = items.first,
                      payload.hasPrefix("tab:"),
                      let draggedTabId = UUID(uuidString: String(payload.dropFirst(4))),
                      draggedTabId != tab.id else {
                    return false
                }
                onDropTabBefore(draggedTabId)
                return true
            },
            isTargeted: { isTargeted in
                self.isDropTargeted = isTargeted
            }
        )
    }
}
