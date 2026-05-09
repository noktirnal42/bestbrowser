import Foundation

struct ReadingModePayload: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let url: String
}
