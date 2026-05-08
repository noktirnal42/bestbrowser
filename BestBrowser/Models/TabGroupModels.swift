import Foundation

struct TabGroup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var colorKey: String
    var isCollapsed: Bool

    init(
        id: UUID = UUID(),
        name: String,
        colorKey: String = TabGroup.defaultColorKey,
        isCollapsed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.isCollapsed = isCollapsed
    }

    static let defaultColorKey = "amber"
    static let availableColorKeys = ["amber", "sky", "blue", "mint", "rose"]
}
