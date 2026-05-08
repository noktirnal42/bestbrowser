import SwiftUI

struct HomeDashboardView: View {
    let version: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BestBrowser v\(version)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(BestBrowserBrand.fog)

                    Text("Ground-up rebuild in progress")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.primary)
                }

                rebuildCard(
                    title: "What changes in v0.3",
                    bullets: [
                        "Separate browser core from workspace and AI systems.",
                        "Make site compatibility a first-class service.",
                        "Replace giant root files with smaller feature modules."
                    ]
                )

                rebuildCard(
                    title: "Migration priorities",
                    bullets: [
                        "Navigation and tab lifecycle",
                        "WebKit compatibility and trust controls",
                        "Workspace and memory features on top of a stable shell"
                    ]
                )
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(BestBrowserBrand.darkBg)
    }

    private func rebuildCard(title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BestBrowserBrand.fog)

            ForEach(bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(BestBrowserBrand.secondary)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)

                    Text(bullet)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.86))
                }
            }
        }
        .padding(20)
        .background(BestBrowserBrand.raisedCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(BestBrowserBrand.border.opacity(0.8), lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

