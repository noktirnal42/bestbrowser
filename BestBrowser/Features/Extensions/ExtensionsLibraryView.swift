import SwiftUI
import AppKit

struct ExtensionsLibraryView: View {
    @ObservedObject var extensionHost: BrowserExtensionHost
    @StateObject private var browserModel = BrowserViewModel.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if !matchingExtensions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("READY FOR THIS PAGE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.secondary)

                        ForEach(matchingExtensions) { ext in
                            extensionCard(ext, emphasized: true)
                        }
                    }
                }

                ForEach(groupedCategories, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.rawValue.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)

                        ForEach(extensions(for: category)) { ext in
                            extensionCard(ext, emphasized: false)
                        }
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 920, alignment: .leading)
        }
        .background(BestBrowserBrand.darkBg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Extensions")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("BestBrowser extensions run inside the app itself. This is the right path for a custom WKWebView-based browser, while Safari web extensions stay installed in Safari as a separate Apple extension target.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Label(currentPageDomain, systemImage: "globe")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.secondary)

                Text("\(extensionHost.extensions.count) manifest-backed tools")
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.72))

                Spacer()

                Button("Open Extension Folder") {
                    guard let url = extensionHost.userExtensionsDirectoryURL() else { return }
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(BestBrowserBrand.primary)
            }
        }
    }

    private func extensionCard(_ ext: BrowserExtension, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: ext.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BestBrowserBrand.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(ext.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { extensionHost.isEnabled(ext.id) },
                            set: { _ in extensionHost.toggleEnabled(ext.id) }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }

                    Text(ext.description)
                        .font(.system(size: 12))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Text(ext.placement == .toolbar || ext.placement == .both ? "toolbar" : "library")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(BestBrowserBrand.secondary.opacity(0.12))
                            .clipShape(Capsule())

                        ForEach(ext.suggestedDomains, id: \.self) { domain in
                            Text(domain)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(BestBrowserBrand.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(BestBrowserBrand.primary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            HStack {
                Button("Run Now") {
                    extensionHost.run(ext)
                }
                .buttonStyle(.plain)
                .foregroundColor((extensionHost.isEnabled(ext.id) && canRun(ext)) ? BestBrowserBrand.primary : BestBrowserBrand.border)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BestBrowserBrand.raisedCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BestBrowserBrand.border.opacity(0.7), lineWidth: 1)
                )
                .cornerRadius(10)
                .disabled(!extensionHost.isEnabled(ext.id) || !canRun(ext))

                Spacer()

                Text(statusText(for: ext))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor(for: ext))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(emphasized ? BestBrowserBrand.primary.opacity(0.09) : BestBrowserBrand.raisedCard)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(emphasized ? BestBrowserBrand.primary.opacity(0.6) : BestBrowserBrand.border.opacity(0.82), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private var groupedCategories: [BrowserExtension.Category] {
        [.pageTools, .productivity, .media]
    }

    private func extensions(for category: BrowserExtension.Category) -> [BrowserExtension] {
        extensionHost.extensions.filter { $0.category == category }
    }

    private var currentPageDomain: String {
        guard let host = URL(string: browserModel.url)?.host else {
            return "No page selected"
        }
        return host
    }

    private var currentPageHost: String? {
        URL(string: browserModel.url)?.host?.lowercased()
    }

    private var matchingExtensions: [BrowserExtension] {
        extensionHost.matchingExtensions(for: URL(string: browserModel.url))
    }

    private func canRun(_ ext: BrowserExtension) -> Bool {
        ext.matches(host: currentPageHost)
    }

    private func statusText(for ext: BrowserExtension) -> String {
        if !extensionHost.isEnabled(ext.id) {
            return "Disabled"
        }
        return canRun(ext) ? "Ready" : "Host Mismatch"
    }

    private func statusColor(for ext: BrowserExtension) -> Color {
        if !extensionHost.isEnabled(ext.id) {
            return BestBrowserBrand.border
        }
        return canRun(ext) ? BestBrowserBrand.success : BestBrowserBrand.warning
    }
}
