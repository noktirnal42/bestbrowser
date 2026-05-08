import Foundation
import SwiftUI

struct BrowserExtension: Identifiable, Equatable {
    enum Category: String, Codable, CaseIterable {
        case pageTools = "Page Tools"
        case productivity = "Productivity"
        case media = "Media"
    }

    enum Placement: String, Codable {
        case library
        case toolbar
        case both
    }

    let id: String
    let name: String
    let description: String
    let icon: String
    let category: Category
    let placement: Placement
    let matchDomains: [String]
    let suggestedDomains: [String]
    let command: BrowserCommand?
    let script: String?

    func matches(host: String?) -> Bool {
        guard !matchDomains.isEmpty else { return true }
        guard let host else { return false }

        return matchDomains.contains { pattern in
            if pattern == "*" { return true }
            if host == pattern { return true }
            return host.contains(pattern)
        }
    }
}

private struct BrowserExtensionManifest: Decodable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: String
    let placement: String?
    let matchDomains: [String]?
    let suggestedDomains: [String]
    let command: String?
    let script: String?
}

@MainActor
final class BrowserExtensionHost: ObservableObject {
    static let shared = BrowserExtensionHost()

    @Published private(set) var extensions: [BrowserExtension] = []

    @Published private var enabledIDs: Set<String> = []

    private let defaultsKey = "bestbrowser.extensions.enabled"
    private let userManifestDirectory = "BestBrowser/Extensions"
    private let commandCoordinator: BrowserCommandCoordinator

    init(commandCoordinator: BrowserCommandCoordinator = .shared) {
        self.commandCoordinator = commandCoordinator
        loadExtensions()
        loadState()
    }

    func isEnabled(_ id: String) -> Bool {
        enabledIDs.contains(id)
    }

    func toggleEnabled(_ id: String) {
        if enabledIDs.contains(id) {
            enabledIDs.remove(id)
        } else {
            enabledIDs.insert(id)
        }
        saveState()
    }

    func run(_ ext: BrowserExtension) {
        guard isEnabled(ext.id) else { return }

        if let command = ext.command {
            commandCoordinator.execute(command)
            return
        }

        if let script = ext.script {
            BrowserViewModel.shared.evaluateCurrentPageJavaScript(script)
        }
    }

    func matchingExtensions(for url: URL?) -> [BrowserExtension] {
        let host = url?.host?.lowercased()
        return extensions.filter { $0.matches(host: host) }
    }

    func toolbarExtensions(for url: URL?) -> [BrowserExtension] {
        matchingExtensions(for: url).filter {
            switch $0.placement {
            case .toolbar, .both:
                return true
            case .library:
                return false
            }
        }
    }

    func commandPaletteExtensions(for url: URL?) -> [BrowserExtension] {
        matchingExtensions(for: url).filter { isEnabled($0.id) }
    }

    func userExtensionsDirectoryURL() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directory = appSupport.appendingPathComponent(userManifestDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func loadState() {
        let saved = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? extensions.map(\.id)
        enabledIDs = Set(saved)
    }

    private func saveState() {
        UserDefaults.standard.set(Array(enabledIDs).sorted(), forKey: defaultsKey)
    }

    private func loadExtensions() {
        let manifests = bundledManifests() + userManifests()
        let resolved = manifests.compactMap(resolveExtension)
        extensions = resolved.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func resolveExtension(_ manifest: BrowserExtensionManifest) -> BrowserExtension? {
        guard let category = category(for: manifest.category) else { return nil }
        let resolvedCommand = manifest.command.flatMap { BrowserCommand(rawValue: $0) ?? command(for: $0) }
        guard resolvedCommand != nil || manifest.script != nil else { return nil }
        return BrowserExtension(
            id: manifest.id,
            name: manifest.name,
            description: manifest.description,
            icon: manifest.icon,
            category: category,
            placement: placement(for: manifest.placement) ?? .library,
            matchDomains: manifest.matchDomains ?? [],
            suggestedDomains: manifest.suggestedDomains,
            command: resolvedCommand,
            script: manifest.script
        )
    }

    private func bundledManifests() -> [BrowserExtensionManifest] {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "BundledExtensions") else {
            return []
        }

        return urls.compactMap(loadManifest)
    }

    private func userManifests() -> [BrowserExtensionManifest] {
        guard let directory = userExtensionsDirectoryURL() else { return [] }

        guard let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }

        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap(loadManifest)
    }

    private func loadManifest(from url: URL) -> BrowserExtensionManifest? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(BrowserExtensionManifest.self, from: data)
    }

    private func category(for rawValue: String) -> BrowserExtension.Category? {
        switch rawValue {
        case "pageTools":
            return .pageTools
        case "productivity":
            return .productivity
        case "media":
            return .media
        default:
            return nil
        }
    }

    private func placement(for rawValue: String?) -> BrowserExtension.Placement? {
        switch rawValue {
        case "toolbar":
            return .toolbar
        case "both":
            return .both
        case "library", nil:
            return .library
        default:
            return nil
        }
    }

    private func command(for rawValue: String) -> BrowserCommand? {
        switch rawValue {
        case "openReadingMode":
            return .openReadingMode
        case "cleanPage":
            return .cleanPage
        case "repairVideoLayout":
            return .repairVideoLayout
        case "briefSession":
            return .briefSession
        default:
            return nil
        }
    }
}
