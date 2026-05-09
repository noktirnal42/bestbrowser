import SwiftUI

enum BrowserTabGroupPalette {
    static func color(for key: String) -> Color {
        switch key {
        case "sky": return BestBrowserBrand.primary
        case "blue": return BestBrowserBrand.accent
        case "mint": return BestBrowserBrand.success
        case "rose": return BestBrowserBrand.warning
        default: return BestBrowserBrand.secondary
        }
    }
}
