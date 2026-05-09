import SwiftUI

struct SessionBriefingSection: View {
    let suggestion: String?
    let brief: String
    let onSaveWorkspace: () -> Void

    var body: some View {
        HomePanelSection(title: "Session Briefing") {
            VStack(alignment: .leading, spacing: 8) {
                if let suggestion,
                   !suggestion.isEmpty {
                    Text(suggestion)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                Text(brief)
                    .font(.system(size: 13))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.9))

                Button(action: onSaveWorkspace) {
                    Label("Save As Workspace", systemImage: "square.stack.badge.plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(BestBrowserBrand.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.cardBackground)
            .cornerRadius(10)
        }
    }
}

struct SuggestedWorkspaceRow: View {
    let suggestion: TabGroupSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(suggestion.groupName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Text(suggestion.tabTitles.joined(separator: " • "))
                .font(.system(size: 11))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.8))
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BestBrowserBrand.cardBackground)
        .cornerRadius(10)
    }
}

struct HomePanelSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.border)

            content()
        }
    }
}

struct WorkspaceLaunchRow: View {
    let workspace: Workspace
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workspace.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(workspace.summary ?? workspace.purpose ?? "Saved browsing session")
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "arrow.clockwise.circle")
                    .foregroundColor(BestBrowserBrand.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.cardBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct QuickLinkRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundColor(BestBrowserBrand.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.raisedCard)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(14)
    }
}
