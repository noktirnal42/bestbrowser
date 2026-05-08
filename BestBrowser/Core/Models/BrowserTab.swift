import Foundation

struct BrowserTab: Identifiable, Equatable, Codable {
    let id: UUID
    var url: String
    var title: String
    var favicon: String?
    var groupId: UUID?
}

