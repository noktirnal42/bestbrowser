import SwiftUI

struct WorkspaceSidebarView: View {
    @ObservedObject var workspaceService: WorkspaceService
    @State private var selectedWorkspaceID: Int64?
    @State private var workspaceTabs: [WorkspaceTab] = []
    @State private var workspacePreviewMeta: [Int64: WorkspacePreviewMeta] = [:]
    @State private var draftTitle = ""
    @State private var draftPurpose = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Button(action: {
                    Task {
                        await workspaceService.refreshSessionInsights()
                        await workspaceService.createWorkspaceFromCurrentSession()
                    }
                }) {
                    Label("Save Current Session", systemImage: "square.stack.badge.plus")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .background(BestBrowserBrand.cardBackground)
                .border(BestBrowserBrand.primary, width: 1)

                if let suggestion = workspaceService.latestSessionTitleSuggestion, !suggestion.isEmpty {
                    Text("Suggested title: \(suggestion)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let brief = workspaceService.latestSessionBrief, !brief.isEmpty {
                    Text(brief)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(BestBrowserBrand.cardBackground)
                        .cornerRadius(8)
                }
            }
            .padding(8)

            ScrollView {
                VStack(spacing: 10) {
                    if workspaceService.workspaces.isEmpty {
                        emptyState
                    } else {
                        ForEach(workspaceService.workspaces) { workspace in
                            WorkspaceCardView(
                                workspace: workspace,
                                previewMeta: workspace.id.flatMap { workspacePreviewMeta[$0] },
                                isSelected: workspace.id == selectedWorkspaceID,
                                onSelect: {
                                    selectedWorkspaceID = workspace.id
                                    loadTabs(for: workspace)
                                },
                                onOpen: {
                                    Task { await workspaceService.openWorkspace(workspace) }
                                },
                                onSave: {
                                    Task { await workspaceService.saveCurrentSession(into: workspace) }
                                },
                                onDelete: {
                                    Task {
                                        if selectedWorkspaceID == workspace.id {
                                            selectedWorkspaceID = nil
                                            workspaceTabs = []
                                        }
                                        await workspaceService.deleteWorkspace(workspace)
                                    }
                                }
                            )
                        }
                    }

                    if let selectedWorkspace = selectedWorkspace {
                        detailEditor(for: selectedWorkspace)
                    }
                }
                .padding(8)
            }
        }
        .task {
            await workspaceService.refresh()
            await workspaceService.refreshSessionInsights()
            await loadPreviewMetadata()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshWorkspaceSession)) { _ in
            Task { await workspaceService.refreshSessionInsights() }
        }
        .onChange(of: workspaceService.workspaces.map(\.uuid)) { _, _ in
            Task { await loadPreviewMetadata() }
        }
    }

    private var selectedWorkspace: Workspace? {
        workspaceService.workspaces.first(where: { $0.id == selectedWorkspaceID })
    }

    @ViewBuilder
    private func detailEditor(for workspace: Workspace) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKSPACE DETAILS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.border)

            TextField("Title", text: Binding(
                get: { draftTitle.isEmpty ? workspace.title : draftTitle },
                set: { draftTitle = $0 }
            ))
            .textFieldStyle(.roundedBorder)

            TextField("Purpose", text: Binding(
                get: { draftPurpose.isEmpty ? (workspace.purpose ?? "") : draftPurpose },
                set: { draftPurpose = $0 }
            ))
            .textFieldStyle(.roundedBorder)

            if let summary = workspace.summary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !workspaceTabs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TABS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.border)

                    ForEach(groupedTabSections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.title)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(BestBrowserBrand.secondary)

                            ForEach(section.tabs.prefix(6)) { tab in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tab.title ?? tab.url)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(tab.url)
                                        .font(.caption2)
                                        .foregroundColor(BestBrowserBrand.fog.opacity(0.8))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }

            Button("Update Workspace") {
                Task {
                    await workspaceService.updateWorkspace(
                        workspace,
                        title: (draftTitle.isEmpty ? workspace.title : draftTitle),
                        purpose: (draftPurpose.isEmpty ? (workspace.purpose ?? "") : draftPurpose),
                        summary: workspace.summary
                    )
                    draftTitle = ""
                    draftPurpose = ""
                }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(BestBrowserBrand.primary)
        }
        .padding(10)
        .background(BestBrowserBrand.cardBackground)
        .cornerRadius(8)
    }

    private var emptyState: some View {
        Text("Save your current tabs into a workspace to build goal-based browsing sessions.")
            .font(.caption)
            .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.cardBackground)
            .cornerRadius(8)
    }

    private func loadTabs(for workspace: Workspace) {
        Task {
            workspaceTabs = await workspaceService.tabs(for: workspace)
        }
    }

    private func loadPreviewMetadata() async {
        var next: [Int64: WorkspacePreviewMeta] = [:]
        for workspace in workspaceService.workspaces {
            guard let id = workspace.id else { continue }
            let tabs = await workspaceService.tabs(for: workspace)
            let groupNames = tabs
                .compactMap(\.groupName)
                .filter { !$0.isEmpty }
                .reduce(into: [String]()) { names, groupName in
                    if !names.contains(groupName) {
                        names.append(groupName)
                    }
                }

            next[id] = WorkspacePreviewMeta(
                tabCount: tabs.count,
                groupCount: groupNames.count,
                groupNames: Array(groupNames.prefix(3))
            )
        }
        workspacePreviewMeta = next
    }

    private var groupedTabSections: [(title: String, tabs: [WorkspaceTab])] {
        let grouped = Dictionary(grouping: workspaceTabs) { tab in
            tab.groupName?.isEmpty == false ? tab.groupName! : "Ungrouped"
        }

        let orderedGroupedNames = workspaceTabs
            .compactMap(\.groupName)
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { names, name in
                if !names.contains(name) {
                    names.append(name)
                }
            }

        let orderedTitles = (grouped["Ungrouped"] == nil ? [] : ["Ungrouped"]) + orderedGroupedNames
        return orderedTitles.compactMap { title in
            guard let tabs = grouped[title], !tabs.isEmpty else { return nil }
            return (title, tabs)
        }
    }
}

private struct WorkspacePreviewMeta {
    let tabCount: Int
    let groupCount: Int
    let groupNames: [String]
}

private struct WorkspaceCardView: View {
    let workspace: Workspace
    let previewMeta: WorkspacePreviewMeta?
    let isSelected: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workspace.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let purpose = workspace.purpose, !purpose.isEmpty {
                        Text(purpose)
                            .font(.system(size: 11))
                            .foregroundColor(BestBrowserBrand.fog.opacity(0.8))
                            .lineLimit(2)
                    }
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(BestBrowserBrand.error)
                }
                .buttonStyle(.plain)
            }

            if let summary = workspace.summary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.8))
                    .lineLimit(3)
            }

            if let previewMeta {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        previewPill("\(previewMeta.tabCount) tabs")
                        if previewMeta.groupCount > 0 {
                            previewPill("\(previewMeta.groupCount) groups")
                        }
                    }

                    if !previewMeta.groupNames.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(previewMeta.groupNames, id: \.self) { groupName in
                                previewPill(groupName)
                            }
                        }
                    }
                }
            }

            HStack {
                Text(workspace.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
                Spacer()
                Button("Save") { onSave() }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundColor(BestBrowserBrand.secondary)
                Button("Open") { onOpen() }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundColor(BestBrowserBrand.primary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? BestBrowserBrand.primary.opacity(0.12) : BestBrowserBrand.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? BestBrowserBrand.primary : BestBrowserBrand.border, lineWidth: 0.8)
        )
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    @ViewBuilder
    private func previewPill(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(BestBrowserBrand.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(BestBrowserBrand.raisedCard)
            .clipShape(Capsule())
    }
}
