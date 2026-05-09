import SwiftUI

struct SplitTabPickerSheet: View {
    let tabs: [BrowserTab]
    let onSelect: (BrowserTab) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Second Tab")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            if tabs.isEmpty {
                Text("Open another page first, then try split view again.")
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(tabs) { tab in
                            Button(action: { onSelect(tab) }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tab.title.isEmpty ? tab.url : tab.title)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(tab.url)
                                            .font(.system(size: 11))
                                            .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "rectangle.split.2x1")
                                        .foregroundColor(BestBrowserBrand.secondary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BestBrowserBrand.raisedCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(BestBrowserBrand.border.opacity(0.75), lineWidth: 1)
                                )
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(BestBrowserBrand.border)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 320)
        .background(BestBrowserBrand.darkBg)
    }
}
