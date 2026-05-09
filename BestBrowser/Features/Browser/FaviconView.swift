import SwiftUI

struct FaviconView: View {
    let faviconURL: String?
    let isActive: Bool

    var body: some View {
        if let faviconURL,
           let url = URL(string: faviconURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                default:
                    fallback
                }
            }
            .frame(width: 12, height: 12)
        } else {
            fallback
        }
    }

    private var fallback: some View {
        Image(systemName: "globe")
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .foregroundColor(isActive ? BestBrowserBrand.primary : BestBrowserBrand.border)
    }
}
