import Foundation
import SwiftUI

@MainActor
class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()

    @Published var downloads: [Download] = []
    @Published var activeDownloads: Int = 0

    private var session: URLSession!
    private var taskMap: [UUID: URLSessionDownloadTask] = [:]
    private let persistenceURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("com.bestbrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("downloads.json")
    }()

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "BestBrowser/0.2.0"]
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        loadDownloads()
    }

    // MARK: - Download Operations

    func addDownload(url: String, filename: String) -> Download {
        let download = Download(
            id: UUID(),
            url: url,
            filename: filename,
            fileSize: 0,
            downloadedSize: 0,
            progress: 0,
            status: .pending,
            startTime: Date(),
            completionTime: nil,
            downloadPath: getDownloadPath(filename)
        )

        downloads.append(download)
        activeDownloads += 1

        startDownload(download)
        persistDownloads()

        return download
    }

    func addDownload(from url: URL, suggestedFilename: String? = nil) -> Download {
        let filename = suggestedFilename ?? (url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent)
        return addDownload(url: url.absoluteString, filename: filename)
    }

    func cancelDownload(id: UUID) {
        if let task = taskMap[id] {
            task.cancel()
            taskMap.removeValue(forKey: id)
        }
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].status = .cancelled
            activeDownloads = max(0, activeDownloads - 1)
            persistDownloads()
        }
    }

    func pauseDownload(id: UUID) {
        if let task = taskMap[id] {
            task.suspend()
            if let index = downloads.firstIndex(where: { $0.id == id }) {
                downloads[index].status = .paused
                persistDownloads()
            }
        }
    }

    func resumeDownload(id: UUID) {
        if let task = taskMap[id] {
            task.resume()
            if let index = downloads.firstIndex(where: { $0.id == id }) {
                downloads[index].status = .downloading
                persistDownloads()
            }
        } else if let index = downloads.firstIndex(where: { $0.id == id }), downloads[index].status == .paused {
            downloads[index].status = .pending
            startDownload(downloads[index])
        }
    }

    func removeDownload(id: UUID) {
        taskMap.removeValue(forKey: id)
        downloads.removeAll { $0.id == id }
        persistDownloads()
    }

    func retryDownload(id: UUID) {
        guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        downloads[index].downloadedSize = 0
        downloads[index].progress = 0
        downloads[index].fileSize = 0
        downloads[index].status = .pending
        downloads[index].completionTime = nil
        activeDownloads += 1
        startDownload(downloads[index])
        persistDownloads()
    }

    func clearCompleted() {
        downloads.removeAll { $0.status == .completed || $0.status == .cancelled || $0.status == .failed }
        persistDownloads()
    }

    func openFile(id: UUID) {
        guard let download = downloads.first(where: { $0.id == id }),
              download.status == .completed else { return }
        let path = URL(fileURLWithPath: download.downloadPath)
        NSWorkspace.shared.open(path)
    }

    func revealInFinder(id: UUID) {
        guard let download = downloads.first(where: { $0.id == id }),
              download.status == .completed else { return }
        let path = URL(fileURLWithPath: download.downloadPath)
    NSApp.activate(ignoringOtherApps: true)
    NSWorkspace.shared.selectFile(path.path, inFileViewerRootedAtPath: "")
    }

    func openSourcePage(id: UUID) {
        guard let download = downloads.first(where: { $0.id == id }),
              let sourceURL = URL(string: download.url) else { return }
        NSWorkspace.shared.open(sourceURL)
    }

    // MARK: - Private Helpers

    private func startDownload(_ download: Download) {
        guard let url = URL(string: download.url) else {
            if let index = downloads.firstIndex(where: { $0.id == download.id }) {
                downloads[index].status = .failed
                activeDownloads = max(0, activeDownloads - 1)
                persistDownloads()
            }
            return
        }

        let task = session.downloadTask(with: url)

        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            downloads[index].status = .downloading
            persistDownloads()
        }

        taskMap[download.id] = task
        task.resume()
    }

    private func getDownloadPath(_ filename: String) -> String {
        let downloadDir = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        let bestBrowserDir = downloadDir.appendingPathComponent("BestBrowser")

        try? FileManager.default.createDirectory(at: bestBrowserDir, withIntermediateDirectories: true)

        let safeFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
        return bestBrowserDir.appendingPathComponent(safeFilename).path
    }

    private func loadDownloads() {
        guard let data = try? Data(contentsOf: persistenceURL),
              let saved = try? JSONDecoder().decode([Download].self, from: data) else {
            return
        }

        downloads = saved.map { download in
            var adjusted = download
            if adjusted.status == .downloading || adjusted.status == .pending {
                adjusted.status = .failed
            }
            return adjusted
        }
        activeDownloads = downloads.filter { $0.status == .downloading || $0.status == .pending || $0.status == .paused }.count
    }

    private func persistDownloads() {
        guard let data = try? JSONEncoder().encode(downloads) else { return }
        try? data.write(to: persistenceURL)
    }

    // MARK: - URLSessionDownloadDelegate

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        Task { @MainActor in
            guard let taskId = taskMap.first(where: { $0.value == downloadTask })?.key,
                  let index = downloads.firstIndex(where: { $0.id == taskId }) else { return }

            let destination = URL(fileURLWithPath: downloads[index].downloadPath)

            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: location, to: destination)
                downloads[index].status = .completed
                downloads[index].completionTime = Date()
                if let attrs = try? FileManager.default.attributesOfItem(atPath: destination.path),
                   let fileSize = attrs[.size] as? Int64 {
                    downloads[index].fileSize = fileSize
                    downloads[index].downloadedSize = fileSize
                    downloads[index].progress = 1.0
                }
            } catch {
                downloads[index].status = .failed
            }

            activeDownloads = max(0, activeDownloads - 1)
            taskMap.removeValue(forKey: taskId)
            persistDownloads()
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task { @MainActor in
            guard let taskId = taskMap.first(where: { $0.value == downloadTask })?.key,
                  let index = downloads.firstIndex(where: { $0.id == taskId }) else { return }

            downloads[index].downloadedSize = totalBytesWritten
            downloads[index].fileSize = totalBytesExpectedToWrite
            downloads[index].progress = totalBytesExpectedToWrite > 0
                ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                : 0
            persistDownloads()
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
    guard let _ = error,
          let downloadTask = task as? URLSessionDownloadTask else { return }

        Task { @MainActor in
            guard let taskId = taskMap.first(where: { $0.value == downloadTask })?.key,
                  let index = downloads.firstIndex(where: { $0.id == taskId }) else { return }

            if downloads[index].status != .cancelled {
                downloads[index].status = .failed
                activeDownloads = max(0, activeDownloads - 1)
            }
            taskMap.removeValue(forKey: taskId)
            persistDownloads()
        }
    }
}

// MARK: - Models

struct Download: Identifiable, Codable {
    let id: UUID
    let url: String
    let filename: String
    var fileSize: Int64
    var downloadedSize: Int64
    var progress: Double
    var status: DownloadStatus
    let startTime: Date
    var completionTime: Date?
    let downloadPath: String

    enum DownloadStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case downloading = "Downloading"
        case paused = "Paused"
        case completed = "Completed"
        case cancelled = "Cancelled"
        case failed = "Failed"

        var icon: String {
            switch self {
            case .pending: return "hourglass"
            case .downloading: return "arrow.down.circle.fill"
            case .paused: return "pause.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .cancelled: return "xmark.circle.fill"
            case .failed: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .pending: return BestBrowserBrand.border
            case .downloading: return BestBrowserBrand.primary
            case .paused: return BestBrowserBrand.secondary
            case .completed: return BestBrowserBrand.success
            case .cancelled: return BestBrowserBrand.border
            case .failed: return BestBrowserBrand.error
            }
        }
    }

    var formattedFileSize: String {
        formatBytes(fileSize)
    }

    var formattedDownloadedSize: String {
        formatBytes(downloadedSize)
    }

    var estimatedTimeRemaining: String {
        guard status == .downloading, progress > 0, progress < 1 else { return "" }

        let elapsed = Date().timeIntervalSince(startTime)
        let estimatedTotal = elapsed / progress
        let remaining = estimatedTotal - elapsed

        if remaining < 60 {
            return "\(Int(remaining))s"
        } else if remaining < 3600 {
            return "\(Int(remaining / 60))m"
        } else {
            return "\(Int(remaining / 3600))h"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
