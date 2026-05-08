//
//  ThemeManager.swift
//  BestBrowser
//
//  Manages Light/Dark/System theme with persistence
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            saveTheme()
            applyTheme()
        }
    }
    
    @Published var colorScheme: ColorScheme?
    
    private let themeKey = "com.bestbrowser.theme"
    private var appearanceSubscription: AnyCancellable?
    
    init() {
        self.currentTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "com.bestbrowser.theme") ?? "system") ?? .system
        applyTheme()
        setupAppearanceObserver()
    }
    
    private func setupAppearanceObserver() {
        appearanceSubscription = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateColorScheme()
            }
    }
    
    private func applyTheme() {
        switch currentTheme {
        case .system:
            colorScheme = nil
            updateColorScheme()
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }
    
    private func updateColorScheme() {
        guard currentTheme == .system else { return }
        
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            colorScheme = .dark
        } else {
            colorScheme = .light
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    func toggle() {
        let allCases = AppTheme.allCases
        let currentIndex = allCases.firstIndex(of: currentTheme) ?? 0
        let nextIndex = (currentIndex + 1) % allCases.count
        currentTheme = allCases[nextIndex]
    }
}
