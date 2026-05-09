import SwiftUI

struct TabBarView: View {
    let tabs: [BrowserTab]
    let groups: [TabGroup]
    let activeTabId: UUID?
    let onSelectTab: (UUID) -> Void
    let onCloseTab: (UUID) -> Void
    let onNewTab: () -> Void
    let onCreateGroup: () -> Void
    let onToggleVerticalTabs: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("Sessions")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.5))
                .padding(.leading, 10)
                .padding(.trailing, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == activeTabId,
                            onSelect: { onSelectTab(tab.id) },
                            onClose: { onCloseTab(tab.id) }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 40)

            Button(action: onNewTab) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("New")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(BestBrowserBrand.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BestBrowserBrand.secondary.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(BestBrowserBrand.secondary.opacity(0.45), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 6)

            if !tabs.isEmpty {
                Button(action: onCreateGroup) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BestBrowserBrand.secondary)
                        .padding(8)
                        .background(BestBrowserBrand.raisedCard)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Group current tab")
            }

            Button(action: onToggleVerticalTabs) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BestBrowserBrand.primary)
                    .padding(8)
                    .background(BestBrowserBrand.raisedCard)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Switch to vertical tabs")
            .padding(.horizontal, 10)
        }
        .background(BestBrowserBrand.chrome)
    }
}

struct TabItemView: View {
    let tab: BrowserTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            FaviconView(faviconURL: tab.favicon, isActive: isActive)

            Text(tab.title)
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(1)
                .foregroundColor(isActive ? .white : BestBrowserBrand.fog.opacity(0.72))

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? BestBrowserBrand.secondary.opacity(0.18) : BestBrowserBrand.raisedCard.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? BestBrowserBrand.secondary.opacity(0.45) : BestBrowserBrand.border.opacity(0.55), lineWidth: 1)
        )
        .cornerRadius(10)
        .onTapGesture(perform: onSelect)
    }
}
