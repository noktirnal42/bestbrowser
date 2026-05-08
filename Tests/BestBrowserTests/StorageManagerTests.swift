import Foundation
import XCTest
@testable import BestBrowser

@MainActor
final class StorageManagerTests: XCTestCase {
    private func makeStorage() throws -> StorageManager {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return StorageManager(databaseURL: directory.appendingPathComponent("test.db"))
    }

    func testWorkspaceRoundTripPersistsTabs() async throws {
        let storage = try makeStorage()
        try await storage.waitUntilInitialized()

        let workspace = try await storage.createWorkspace(
            title: "Research Session",
            purpose: "Compare sources",
            summary: "Saved session",
            status: .active
        )

        let workspaceId = try XCTUnwrap(workspace.id)
        try await storage.replaceWorkspaceTabs(
            workspaceId: workspaceId,
            tabs: [
                WorkspaceTab(
                    workspaceId: workspaceId,
                    url: "https://example.com/a",
                    title: "A",
                    groupName: "Research",
                    groupColorKey: "amber"
                ),
                WorkspaceTab(workspaceId: workspaceId, url: "https://example.com/b", title: "B")
            ]
        )

        let fetchedWorkspaces = try await storage.getWorkspaces()
        let fetchedTabs = try await storage.getWorkspaceTabs(workspaceId: workspaceId)

        XCTAssertEqual(fetchedWorkspaces.first?.title, "Research Session")
        XCTAssertEqual(fetchedTabs.count, 2)
        XCTAssertEqual(fetchedTabs.first?.url, "https://example.com/a")
        XCTAssertEqual(fetchedTabs.first?.groupName, "Research")
        XCTAssertEqual(fetchedTabs.first?.groupColorKey, "amber")
    }

    func testPageMemorySupportsPinnedNotes() async throws {
        let storage = try makeStorage()
        try await storage.waitUntilInitialized()

        try await storage.upsertPageMemory(
            PageMemory(
                url: "https://example.com/article",
                normalizedUrl: "https://example.com/article",
                title: "Example",
                host: "example.com",
                summary: "Summary",
                takeaway: "Takeaway",
                keywords: "browser, memory",
                note: nil,
                isPinned: false
            )
        )

        let memories = try await storage.getPageMemories(limit: 1)
        let memory = try XCTUnwrap(memories.first)
        let memoryId = try XCTUnwrap(memory.id)

        try await storage.updatePageMemory(id: memoryId, note: "Keep this for later", isPinned: true)
        let updatedMemories = try await storage.getPageMemories(limit: 1)
        let updated = try XCTUnwrap(updatedMemories.first)

        XCTAssertEqual(updated.note, "Keep this for later")
        XCTAssertTrue(updated.isPinned)
    }

    func testWatchRuleSnapshotsPersist() async throws {
        let storage = try makeStorage()
        try await storage.waitUntilInitialized()

        let rule = try await storage.createWatchRule(
            url: "https://example.com/pricing",
            title: "Pricing",
            watchType: "page-change",
            prompt: "Monitor pricing changes"
        )

        let ruleId = try XCTUnwrap(rule.id)
        try await storage.addWatchSnapshot(
            WatchSnapshot(
                watchRuleId: ruleId,
                contentHash: "abc123",
                summary: "Pricing page baseline",
                changeSummary: "Baseline snapshot created."
            )
        )

        let latestSnapshot = try await storage.getLatestWatchSnapshot(ruleId: ruleId)
        XCTAssertEqual(latestSnapshot?.contentHash, "abc123")
        XCTAssertEqual(latestSnapshot?.summary, "Pricing page baseline")
    }
}
