import SwiftUI

struct DownloadManagerView: View {
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var showingCompleted = true

    var activeDownloads: [Download] {
        downloadManager.downloads.filter { $0.status == .downloading || $0.status == .pending || $0.status == .paused }
    }

    var completedDownloads: [Download] {
        downloadManager.downloads.filter { $0.status == .completed || $0.status == .cancelled || $0.status == .failed }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(BestBrowserBrand.primary)
                    .neonGlow(BestBrowserBrand.primary, radius: 3)
                Text("DOWNLOADS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.primary)
                Spacer()
                if !completedDownloads.isEmpty {
                    Button(action: { downloadManager.clearCompleted() }) {
                        Text("Clear All")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .buttonStyle(.cyberpunk)
                }
            }
            .padding(12)
            .background(BestBrowserBrand.cardBackground)
            .border(BestBrowserBrand.border, width: 1)

            if downloadManager.downloads.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 40))
                        .foregroundColor(BestBrowserBrand.border)
                    Text("No downloads yet")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.border)
                    Text("Files you download will appear here")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        if !activeDownloads.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ACTIVE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(BestBrowserBrand.border)
                                    .padding(.horizontal, 4)

                                ForEach(activeDownloads) { download in
                                    DownloadItemView(download: download, downloadManager: downloadManager)
                                }
                            }
                            .padding(8)
                            .background(BestBrowserBrand.darkCard)
                            .border(BestBrowserBrand.border, width: 1)
                            .cornerRadius(6)
                            .padding(.horizontal, 8)
                        }

                        if !completedDownloads.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("COMPLETED")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(BestBrowserBrand.border)

                                    Spacer()

                                    Button(action: { showingCompleted.toggle() }) {
                                        Image(systemName: showingCompleted ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(BestBrowserBrand.border)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 4)

                                if showingCompleted {
                                    ForEach(completedDownloads) { download in
                                        DownloadItemView(download: download, downloadManager: downloadManager)
                                    }
                                }
                            }
                            .padding(8)
                            .background(BestBrowserBrand.darkCard)
                            .border(BestBrowserBrand.border, width: 1)
                            .cornerRadius(6)
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(BestBrowserBrand.darkBg)
    }
}

struct DownloadItemView: View {
    let download: Download
    let downloadManager: DownloadManager

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: download.status.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(download.status.color)
                    .neonGlow(download.status.color, radius: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(download.filename)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .lineLimit(1)
                        .foregroundColor(BestBrowserBrand.primary)

                    Text(download.url)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(1)
                        .foregroundColor(BestBrowserBrand.border)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(download.status.rawValue)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(download.status.color)
                }
            }

            if download.status == .downloading || download.status == .pending {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(BestBrowserBrand.border.opacity(0.3))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [BestBrowserBrand.primary, BestBrowserBrand.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(download.progress), height: 4)
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text("\(download.formattedDownloadedSize) / \(download.formattedFileSize)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)

                        Spacer()

                        Text("\(Int(download.progress * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.primary)

                        if !download.estimatedTimeRemaining.isEmpty {
                            Text(download.estimatedTimeRemaining)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(BestBrowserBrand.border)
                        }
                    }
                }
            } else if download.status == .completed {
                HStack {
                    Text(download.formattedFileSize)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.border)

                    Spacer()

                    if let completion = download.completionTime {
                        Text(completion.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)
                    }
                }
            } else if download.status == .failed {
                Text("Download failed — tap retry")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.error)
            }

            HStack(spacing: 6) {
                if download.status == .downloading {
                    DownloadControlButton(icon: "pause.fill") { downloadManager.pauseDownload(id: download.id) }
                    DownloadControlButton(icon: "xmark.circle.fill", color: BestBrowserBrand.error) { downloadManager.cancelDownload(id: download.id) }
                } else if download.status == .paused {
                    DownloadControlButton(icon: "play.fill") { downloadManager.resumeDownload(id: download.id) }
                    DownloadControlButton(icon: "xmark.circle.fill", color: BestBrowserBrand.error) { downloadManager.cancelDownload(id: download.id) }
                } else {
                    DownloadControlButton(icon: "trash.fill", color: BestBrowserBrand.error) { downloadManager.removeDownload(id: download.id) }
                    if download.status == .failed || download.status == .cancelled {
                        DownloadControlButton(icon: "arrow.clockwise") { downloadManager.retryDownload(id: download.id) }
                    }
                }

                Spacer()

                if download.status == .completed {
                    DownloadControlButton(icon: "folder.fill") { downloadManager.revealInFinder(id: download.id) }
                    DownloadControlButton(icon: "arrow.up.right.square") { downloadManager.openFile(id: download.id) }
                }

                DownloadControlButton(icon: "safari") { downloadManager.openSourcePage(id: download.id) }
            }
        }
        .padding(10)
        .background(BestBrowserBrand.cardBackground)
        .border(BestBrowserBrand.border, width: 0.5)
        .cornerRadius(6)
    }
}

struct DownloadControlButton: View {
    let icon: String
    var color: Color = BestBrowserBrand.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
                .padding(6)
                .background(color.opacity(0.1))
                .cornerRadius(4)
                .border(color.opacity(0.3), width: 0.5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DownloadManagerView()
}
