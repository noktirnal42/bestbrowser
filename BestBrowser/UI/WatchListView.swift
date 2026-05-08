import SwiftUI

struct WatchListView: View {
    @ObservedObject var watchService: WatchService

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Button(action: {
                    Task { await watchService.addCurrentPageWatch() }
                }) {
                    Label("Watch Current Page", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .background(BestBrowserBrand.cardBackground)
                .border(BestBrowserBrand.primary, width: 1)

                Button(action: {
                    Task { await watchService.checkAll() }
                }) {
                    HStack {
                        if watchService.isChecking {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check All")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                }
                .buttonStyle(.plain)
                .background(BestBrowserBrand.cardBackground)
                .border(BestBrowserBrand.border, width: 1)

                if case .unavailable(let message) = watchService.notificationAccessState {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(BestBrowserBrand.warning)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notifications Off")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)

                            Text(message)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.82))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button("Open Settings") {
                            watchService.openNotificationsSettings()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BestBrowserBrand.primary)
                    }
                    .padding(10)
                    .background(BestBrowserBrand.cardBackground)
                    .cornerRadius(8)
                }

                if let message = visibleStatusMessage {
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(BestBrowserBrand.cardBackground)
                        .cornerRadius(8)
                }
            }
            .padding(8)

            ScrollView {
                VStack(spacing: 8) {
                    if watchService.watchItems.isEmpty {
                        Text("Watched pages will appear here with change summaries and timestamps.")
                            .font(.caption)
                            .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BestBrowserBrand.cardBackground)
                            .cornerRadius(8)
                    } else {
                        ForEach(watchService.watchItems) { item in
                            WatchCardView(
                                item: item,
                                onToggle: { Task { await watchService.toggle(item) } },
                                onDelete: { Task { await watchService.delete(item) } },
                                onCheck: { Task { await watchService.check(item.rule); await watchService.refresh() } }
                            )
                        }
                    }
                }
                .padding(8)
            }
        }
        .task {
            await watchService.refresh()
        }
    }

    private var visibleStatusMessage: String? {
        guard let message = watchService.statusMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else {
            return nil
        }

        if message.localizedCaseInsensitiveContains("UNErrorDomain")
            || message.localizedCaseInsensitiveContains("notification permission failed") {
            return nil
        }

        return message
    }
}

private struct WatchCardView: View {
    let item: WatchStatusSummary
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onCheck: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.rule.title ?? item.rule.url)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text(item.rule.url)
                        .font(.caption2)
                        .foregroundColor(BestBrowserBrand.border)
                        .lineLimit(1)
                }
                Spacer()
                Text(item.rule.status.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(item.rule.status == .active ? BestBrowserBrand.success : BestBrowserBrand.warning)
            }

            if let summary = item.latestSnapshot?.summary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(3)
            }

            if let change = item.latestSnapshot?.changeSummary, !change.isEmpty {
                Text(change)
                    .font(.system(size: 11))
                    .foregroundColor(BestBrowserBrand.fog.opacity(0.8))
                    .lineLimit(3)
            }

            HStack {
                Button("Check") { onCheck() }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundColor(BestBrowserBrand.primary)
                Button(item.rule.status == .active ? "Pause" : "Resume") { onToggle() }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundColor(BestBrowserBrand.secondary)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(BestBrowserBrand.error)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BestBrowserBrand.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(BestBrowserBrand.border, lineWidth: 0.8)
        )
    }
}
