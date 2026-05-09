import SwiftUI

struct ToolbarTitleCluster: View {
    let focusedPaneLabel: String
    let focusedTabTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(focusedPaneLabel.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.secondary)

            Text(focusedTabTitle.isEmpty ? "Untitled Page" : focusedTabTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.82))
                .lineLimit(1)
        }
        .frame(width: 170, alignment: .leading)
        .padding(.leading, 2)
    }
}

struct ToolbarNavigationCluster: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            NavButton(icon: "chevron.left", enabled: canGoBack, helpText: "Back", action: onBack)
            NavButton(icon: "chevron.right", enabled: canGoForward, helpText: "Forward", action: onForward)
            NavButton(icon: "arrow.clockwise", enabled: true, helpText: "Reload page", action: onRefresh)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(BestBrowserBrand.raisedCard)
        .overlay(
            Capsule().stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct ToolbarAddressField: View {
    let url: String
    @Binding var urlText: String
    let isSecure: Bool
    let isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(BestBrowserBrand.secondary)

            TextField("Search or enter URL", text: $urlText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
                .focused(isFocused)
                .onSubmit {
                    onSubmit()
                }

            if !urlText.isEmpty && isFocused.wrappedValue {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(BestBrowserBrand.border)
                }
                .buttonStyle(.plain)
            }

            if isSecure {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(BestBrowserBrand.success)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(BestBrowserBrand.raisedCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isFocused.wrappedValue
                        ? BestBrowserBrand.secondary.opacity(0.52)
                        : BestBrowserBrand.border.opacity(0.8),
                    lineWidth: 1
                )
        )
        .cornerRadius(18)
        .onChange(of: url) { _, newValue in
            urlText = newValue
        }
    }
}

struct ToolbarSecurityBadge: View {
    let isSecure: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(isSecure ? "Secure" : "Open")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isSecure ? BestBrowserBrand.success : BestBrowserBrand.border)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(BestBrowserBrand.raisedCard)
        .overlay(
            Capsule().stroke(BestBrowserBrand.border.opacity(0.7), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct ToolbarActionButton: View {
    let icon: String
    let tint: Color
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(tint)
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}

struct NavButton: View {
    let icon: String
    let enabled: Bool
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(enabled ? BestBrowserBrand.primary : BestBrowserBrand.border.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(helpText)
    }
}
