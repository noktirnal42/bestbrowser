import Foundation

enum AppVersion {
    static let fallbackDisplayVersion = "0.3.1"

    static var displayVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        ?? fallbackDisplayVersion
    }
}
