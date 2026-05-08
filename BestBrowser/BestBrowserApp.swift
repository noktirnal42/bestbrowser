//
//  BestBrowserApp.swift
//  BestBrowser
//
//  Created by Jeremy McVay
//

import SwiftUI
import FoundationModels
import AuthenticationServices

@main
struct BestBrowserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager.shared
    private let commandCoordinator = BrowserCommandCoordinator.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    StartupScreenView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    BrowserSceneRootView()
                        .frame(minWidth: 800, minHeight: 600)
                        .preferredColorScheme(themeManager.colorScheme)
                        .background(BestBrowserBrand.background)
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    commandCoordinator.execute(BrowserCommand.newTab)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Close Tab") {
                    commandCoordinator.execute(BrowserCommand.closeTab)
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("Reopen Closed Tab") {
                    commandCoordinator.execute(BrowserCommand.reopenClosedTab)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button("Toggle Split View") {
                    commandCoordinator.execute(BrowserCommand.toggleSplitView)
                }
                .keyboardShortcut("\\", modifiers: [.command, .shift])

                Button("Toggle Vertical Tabs") {
                    commandCoordinator.execute(BrowserCommand.toggleVerticalTabs)
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])

                Button("Group Current Tab") {
                    commandCoordinator.execute(BrowserCommand.groupCurrentTab)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Divider()

                Button("Toggle Theme") {
                    ThemeManager.shared.toggle()
                }
                .keyboardShortcut("t", modifiers: [.command, .option])

                Button("Preferences...") {
                    commandCoordinator.execute(BrowserCommand.openSettings)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app for macOS 26+
        NSApp.setActivationPolicy(.regular)

        // Initialize subsystems
        _ = StorageManager.shared
        _ = PrivacyShield.shared
        _ = AIClient.shared
        _ = SemanticSearch.shared
        _ = WorkspaceService.shared
        _ = PageMemoryService.shared
        _ = CompareService.shared
        _ = WatchService.shared
        _ = BrowserAuthenticationService.shared
        BrowserAuthenticationService.shared.start()

        print("Apple Foundation Model availability: \(SystemLanguageModel.default.availability)")
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }
}
