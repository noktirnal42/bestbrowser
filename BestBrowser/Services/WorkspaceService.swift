import Foundation

@MainActor
final class WorkspaceService: ObservableObject {
    static let shared = WorkspaceService()

    @Published private(set) var workspaces: [Workspace] = []
    @Published var latestSessionBrief: String?
    @Published var latestSessionTitleSuggestion: String?
    @Published var errorMessage: String?

    private let storage = StorageManager.shared
    private let aiClient = AIClient.shared

    private init() {
        Task {
            await refresh()
            await refreshSessionInsights()
        }
    }

    func refresh() async {
        do {
            workspaces = try await storage.getWorkspaces()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshSessionInsights() async {
        let tabs = sessionSnapshots()
        guard !tabs.isEmpty else {
            latestSessionBrief = nil
            latestSessionTitleSuggestion = nil
            return
        }

        latestSessionBrief = makeHeuristicBrief(from: tabs)

        guard aiClient.isAvailable else {
            latestSessionTitleSuggestion = nil
            return
        }

        let context = tabs
            .enumerated()
            .map { index, tab in "\(index + 1). \(tab.title) — \(tab.url)" }
            .joined(separator: "\n")

        do {
            latestSessionTitleSuggestion = try await aiClient.generateTitle("""
            Suggest a short workspace title for this browsing session:

            \(context)
            """)
        } catch {
            latestSessionTitleSuggestion = nil
        }
    }

    func createWorkspaceFromCurrentSession(title: String? = nil, purpose: String? = nil) async {
        let tabs = sessionSnapshots()
        guard !tabs.isEmpty else {
            errorMessage = "Open a few pages before saving a workspace."
            return
        }

        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = trimmedTitle.flatMap { $0.isEmpty ? nil : $0 }
            ?? latestSessionTitleSuggestion
            ?? defaultWorkspaceTitle(from: tabs)

        let summary = latestSessionBrief ?? makeHeuristicBrief(from: tabs)

        do {
            let workspace = try await storage.createWorkspace(
                title: resolvedTitle,
                purpose: purpose,
                summary: summary,
                status: .active
            )
            try await storage.replaceWorkspaceTabs(
                workspaceId: workspace.id ?? 0,
                tabs: tabs.map {
                    let matchingGroup = BrowserViewModel.shared.group(for: $0.id)
                    return WorkspaceTab(
                        workspaceId: workspace.id ?? 0,
                        url: $0.url,
                        title: $0.title,
                        faviconUrl: $0.faviconUrl,
                        note: $0.note,
                        groupName: matchingGroup?.name,
                        groupColorKey: matchingGroup?.colorKey
                    )
                }
            )
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateWorkspace(_ workspace: Workspace, title: String, purpose: String, summary: String?) async {
        guard let id = workspace.id else { return }

        do {
            try await storage.updateWorkspace(
                id: id,
                title: title,
                purpose: purpose.isEmpty ? nil : purpose,
                summary: summary
            )
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteWorkspace(_ workspace: Workspace) async {
        guard let id = workspace.id else { return }

        do {
            try await storage.deleteWorkspace(id: id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openWorkspace(_ workspace: Workspace) async {
        guard let id = workspace.id else { return }

        do {
            let tabs = try await storage.getWorkspaceTabs(workspaceId: id)
            let snapshots = tabs.map {
                WorkspaceTabSnapshot(
                    url: $0.url,
                    title: $0.title ?? $0.url,
                    faviconUrl: $0.faviconUrl,
                    note: $0.note,
                    groupName: $0.groupName,
                    groupColorKey: $0.groupColorKey
                )
            }
            BrowserViewModel.shared.loadWorkspaceTabs(snapshots)
            try await storage.recordWorkspaceOpened(id: id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCurrentSession(into workspace: Workspace) async {
        guard let id = workspace.id else { return }
        let tabs = sessionSnapshots()
        guard !tabs.isEmpty else { return }

        do {
            try await storage.replaceWorkspaceTabs(
                workspaceId: id,
                tabs: tabs.map {
                    let matchingGroup = BrowserViewModel.shared.group(for: $0.id)
                    return WorkspaceTab(
                        workspaceId: id,
                        url: $0.url,
                        title: $0.title,
                        faviconUrl: $0.faviconUrl,
                        note: $0.note,
                        groupName: matchingGroup?.name,
                        groupColorKey: matchingGroup?.colorKey
                    )
                }
            )
            try await storage.updateWorkspace(
                id: id,
                title: workspace.title,
                purpose: workspace.purpose,
                summary: latestSessionBrief ?? makeHeuristicBrief(from: tabs)
            )
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func tabs(for workspace: Workspace) async -> [WorkspaceTab] {
        guard let id = workspace.id else { return [] }
        return (try? await storage.getWorkspaceTabs(workspaceId: id)) ?? []
    }

    private func sessionSnapshots() -> [WorkspaceTabSnapshot] {
        BrowserViewModel.shared.sessionSnapshots().map {
            WorkspaceTabSnapshot(
                id: $0.id,
                url: $0.url,
                title: $0.title,
                faviconUrl: $0.faviconUrl,
                groupName: BrowserViewModel.shared.group(for: $0.id)?.name,
                groupColorKey: BrowserViewModel.shared.group(for: $0.id)?.colorKey
            )
        }
    }

    private func defaultWorkspaceTitle(from tabs: [WorkspaceTabSnapshot]) -> String {
        if let first = tabs.first?.title, !first.isEmpty {
            return tabs.count == 1 ? first : "\(first) Session"
        }
        return "Workspace \(Date.now.formatted(date: .abbreviated, time: .shortened))"
    }

    private func makeHeuristicBrief(from tabs: [WorkspaceTabSnapshot]) -> String {
        let hosts = tabs
            .compactMap { URL(string: $0.url)?.host() }
            .reduce(into: [String: Int]()) { counts, host in
                counts[host, default: 0] += 1
            }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)

        let topTitles = tabs
            .map(\.title)
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: ", ")

        let hostSummary = hosts.isEmpty ? "a mixed set of sources" : hosts.joined(separator: ", ")
        if topTitles.isEmpty {
            return "This workspace captures \(tabs.count) tabs across \(hostSummary)."
        }
        return "This workspace captures \(tabs.count) tabs across \(hostSummary), centered on \(topTitles)."
    }
}
