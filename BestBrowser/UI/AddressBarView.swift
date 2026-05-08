import SwiftUI

struct AddressBarView: View {
    @Binding var url: String
    @Binding var isEditing: Bool
    @State private var suggestions: [String] = []
    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool

    let onSubmit: (String) -> Void
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Navigation buttons
                HStack(spacing: 4) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BestBrowserBrand.primary)
                    }
                    .disabled(!canGoBack)
                    .opacity(canGoBack ? 1 : 0.3)

                    Button(action: onForward) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BestBrowserBrand.primary)
                    }
                    .disabled(!canGoForward)
                    .opacity(canGoForward ? 1 : 0.3)

                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BestBrowserBrand.primary)
                    }
                }
                .buttonStyle(.plain)

                // Address bar
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 12))
                        .foregroundColor(BestBrowserBrand.secondary)

                    ZStack(alignment: .leading) {
                        if url.isEmpty && !isEditing {
                            Text("Enter URL or search...")
                                .font(.caption)
                                .foregroundColor(BestBrowserBrand.border)
                        }

                        TextField("", text: $url)
                            .font(.caption)
                            .foregroundColor(BestBrowserBrand.primary)
                            .focused($isFocused)
                            .onChange(of: isFocused) { oldValue, newValue in
                                isEditing = newValue
                                if newValue {
                                    showSuggestions = true
                                }
                            }
                            .onSubmit {
                                var urlToLoad = url
                                if !urlToLoad.hasPrefix("http") {
                                    urlToLoad = "https://\(urlToLoad)"
                                }
                                onSubmit(urlToLoad)
                                showSuggestions = false
                            }
                    }

                    if isEditing && !url.isEmpty {
                        Button(action: { url = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(BestBrowserBrand.border)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(BestBrowserBrand.cardBackground)
                .border(
                    isEditing ? BestBrowserBrand.primary : BestBrowserBrand.border,
                    width: 1
                )
                .cornerRadius(4)

                // Menu button
                Menu {
                    Button(action: {}) {
                        Label("Bookmarks", systemImage: "bookmark.fill")
                    }
                    Button(action: {}) {
                        Label("History", systemImage: "clock.fill")
                    }
                    Button(action: {}) {
                        Label("Downloads", systemImage: "arrow.down.circle.fill")
                    }
                    Divider()
                    Button(action: {}) {
                        Label("Settings", systemImage: "gear")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 12))
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(BestBrowserBrand.darkCard)
            .border(BestBrowserBrand.border, width: 1)

            // Suggestions
            if showSuggestions && isEditing && !url.isEmpty {
                VStack(spacing: 0) {
                    Divider()

                    ScrollView {
                        VStack(spacing: 0) {
                            SuggestionItemView(
                                icon: "magnifyingglass",
                                text: "Search: \(url)",
                                color: BestBrowserBrand.secondary
                            )
                            .onTapGesture {
                                onSubmit("https://www.google.com/search?q=\(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url)")
                                showSuggestions = false
                            }

                            ForEach(quickSuggestions(), id: \.self) { suggestion in
                                Divider()
                                    .padding(.horizontal, 0)

                                SuggestionItemView(
                                    icon: "globe",
                                    text: suggestion,
                                    color: BestBrowserBrand.primary
                                )
                                .onTapGesture {
                                    var urlToLoad = suggestion
                                    if !urlToLoad.hasPrefix("http") {
                                        urlToLoad = "https://\(urlToLoad)"
                                    }
                                    onSubmit(urlToLoad)
                                    showSuggestions = false
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(BestBrowserBrand.darkCard)
                }
                .border(BestBrowserBrand.border, width: 1)
            }
        }
    }

    private func quickSuggestions() -> [String] {
        let common = [
            "github.com",
            "stackoverflow.com",
            "wikipedia.org",
            "medium.com",
        ]

        return common.filter { $0.hasPrefix(url.lowercased()) }.prefix(5).map { String($0) }
    }
}

struct SuggestionItemView: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            Text(text)
                .font(.caption)
                .foregroundColor(color)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    AddressBarView(
        url: .constant(""),
        isEditing: .constant(false),
        onSubmit: { _ in },
        canGoBack: true,
        canGoForward: false,
        onBack: {},
        onForward: {},
        onRefresh: {}
    )
}
