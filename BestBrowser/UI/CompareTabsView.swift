import SwiftUI

struct CompareTabsView: View {
    let presentation: ComparePresentation
    let recentSessions: [CompareSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tab Comparison")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(presentation.markdown)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(BestBrowserBrand.cardBackground)
                        .cornerRadius(10)

                    if !presentation.citations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sources")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(BestBrowserBrand.border)

                            ForEach(presentation.citations) { citation in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("[\(citation.index)] \(citation.title)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Text("\(citation.host) • \(citation.url)")
                                        .font(.caption2)
                                        .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                                        .lineLimit(2)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BestBrowserBrand.cardBackground)
                                .cornerRadius(8)
                            }
                        }
                    }

                    if !recentSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Comparisons")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(BestBrowserBrand.border)

                            ForEach(recentSessions.prefix(4)) { session in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title ?? "Comparison")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Text(session.sourceUrls.joined(separator: " • "))
                                        .font(.caption2)
                                        .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                                        .lineLimit(2)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BestBrowserBrand.cardBackground)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 720, minHeight: 520)
        .background(BestBrowserBrand.darkBg)
    }
}
