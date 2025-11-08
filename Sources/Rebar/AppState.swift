import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    @Published var jobs: [ConversionJob] = []
    @Published var dropError: DropError?
    @Published var isImporting = false
    @Published var importFoundCount = 0
    @Published var importStatusMessage: String?
    @Published var presets: [ConversionPreset]
    @Published var selectedPreset: ConversionPreset
    @Published var conversionForm: ConversionForm
    @Published var conversionStatusMessage: String?
    @Published var conversionResult: ConversionResult?
    @Published var conversionSummary: ConversionSummary?
    @Published var conversionErrorMessage: String?
    @Published var isConverting = false
    @Published var isPaused = false
    @Published var shouldStop = false

    private let conversionService: ConversionService
    private var conversionTask: Task<Void, Never>?

    init(conversionService: ConversionService = ConversionService()) {
        self.conversionService = conversionService
        let presets = ConversionPreset.defaults
        self.presets = presets
        let initialPreset = presets.first ?? ConversionPreset.defaults[0]
        self.selectedPreset = initialPreset
        self.conversionForm = initialPreset.makeForm()
    }

    func register(drop urls: [URL]) {
        // Clear thumbnail cache from previous session to free memory
        ThumbnailCache.shared.clearCache()
        
        // Kick off a background scan so the UI stays responsive
        jobs = []
        dropError = nil
        isImporting = true
        importFoundCount = 0
        importStatusMessage = "Scanning…"
        conversionStatusMessage = nil
        conversionErrorMessage = nil
        conversionResult = nil

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let candidates = flattenURLs(urls)
            
            // Batch processing to reduce UI updates
            var newJobs: [ConversionJob] = []
            var processedCount = 0
            let batchSize = 20 // Update UI every 20 files instead of every single file
            
            for url in candidates {
                if FileTypeValidator.isAcceptable(url) {
                    let item = DroppedItem(url: url)
                    newJobs.append(ConversionJob(item: item))
                    processedCount += 1
                    
                    // Batch update UI
                    if processedCount % batchSize == 0 {
                        let jobsToAdd = newJobs
                        let count = processedCount
                        await MainActor.run {
                            self.jobs.append(contentsOf: jobsToAdd)
                            self.importFoundCount = count
                            self.importStatusMessage = "Found \(count) image(s)…"
                        }
                        newJobs.removeAll(keepingCapacity: true)
                    }
                }
            }
            
            // Add remaining items
            let finalJobs = newJobs
            let finalCount = processedCount
            if !finalJobs.isEmpty {
                await MainActor.run {
                    self.jobs.append(contentsOf: finalJobs)
                    self.importFoundCount = finalCount
                }
            }

            await MainActor.run {
                self.isImporting = false
                if self.importFoundCount == 0 {
                    self.dropError = .noUsableFiles
                    self.importStatusMessage = nil
                } else {
                    self.importStatusMessage = "Ready: \(self.importFoundCount) image(s)"
                }
            }
        }
    }

    func selectPreset(_ preset: ConversionPreset) {
        guard selectedPreset != preset else { return }
        selectedPreset = preset
        conversionForm = preset.makeForm()
    }

    func queueConversion() {
        guard !jobs.isEmpty else {
            dropError = .noUsableFiles
            return
        }
        guard !isConverting else { return }

        isConverting = true
        isPaused = false
        shouldStop = false
        conversionStatusMessage = "Converting 0/\(jobs.count)…"
        conversionErrorMessage = nil
        conversionResult = nil
        conversionSummary = Optional<ConversionSummary>.none

        let jobsSnapshot = jobs
        let formSnapshot = conversionForm
        let startTime = Date()

        conversionTask = Task {
            var completedCount = 0
            var failedCount = 0
            var totalOriginalSize: Int64 = 0
            var totalOutputSize: Int64 = 0

            for job in jobsSnapshot {
                // Check if stop was requested
                if await MainActor.run(body: { self.shouldStop }) {
                    break
                }
                
                // Wait while paused
                while await MainActor.run(body: { self.isPaused && !self.shouldStop }) {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                }
                
                // Check again after pause
                if await MainActor.run(body: { self.shouldStop }) {
                    break
                }
                
                // Single update to mark as in-progress (no intermediate stage updates)
                await MainActor.run {
                    self.updateJob(job.id) { job in
                        job.status = .inProgress(step: .loadingInput)
                    }
                }

                do {
                    // Convert without progress callbacks to avoid UI thrashing
                    let result = try await self.conversionService.convert(
                        item: job.item,
                        form: formSnapshot,
                        progress: nil  // Skip intermediate updates for performance
                    )
                    completedCount += 1
                    totalOriginalSize += result.originalSize
                    totalOutputSize += result.outputSize
                    
                    // Batch update: status + message + result in one MainActor call
                    await MainActor.run {
                        self.updateJob(job.id) { job in
                            job.status = .completed(result)
                        }
                        self.conversionStatusMessage = "Converting \(completedCount)/\(jobsSnapshot.count)…"
                        self.conversionResult = result
                    }
                } catch {
                    failedCount += 1
                    await MainActor.run {
                        self.updateJob(job.id) { job in
                            job.status = .failed(error.localizedDescription)
                        }
                    }
                }
            }

            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)

            await MainActor.run {
                let wasStopped = self.shouldStop
                let summary = wasStopped 
                    ? "Stopped: \(completedCount) completed, \(jobsSnapshot.count - completedCount - failedCount) skipped"
                    : (failedCount > 0 
                        ? "Completed \(completedCount), failed \(failedCount)"
                        : "Completed all \(completedCount) file(s)")
                self.conversionStatusMessage = summary
                if completedCount > 0 {
                    self.conversionSummary = ConversionSummary(
                        totalFiles: jobsSnapshot.count,
                        completedCount: completedCount,
                        failedCount: failedCount,
                        totalOriginalSize: totalOriginalSize,
                        totalOutputSize: totalOutputSize,
                        duration: duration
                    )
                }
                self.isConverting = false
                self.isPaused = false
                self.shouldStop = false
            }
        }
    }
    
    func pauseConversion() {
        isPaused = true
    }
    
    func resumeConversion() {
        isPaused = false
    }
    
    func stopConversion() {
        shouldStop = true
        isPaused = false
    }

    func browseForOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            conversionForm.outputDirectoryPath = url.path
        }
    }

    func revealLatestOutput() {
        guard let url = conversionResult?.outputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func updateJob(_ id: UUID, mutate: (inout ConversionJob) -> Void) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        mutate(&jobs[index])
    }

}

// MARK: - Helpers (not actor-isolated)

/// Recursively flatten directories into individual file URLs
private func flattenURLs(_ urls: [URL]) -> [URL] {
    let fm = FileManager.default
    var collected = Set<URL>() // Use Set for automatic deduplication
    
    func processURL(_ url: URL) {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return }
        
        if isDir.boolValue {
            guard let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { return }
            
            for case let fileURL as URL in enumerator {
                if let isRegularFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile,
                   isRegularFile {
                    collected.insert(fileURL.standardizedFileURL)
                }
            }
        } else {
            collected.insert(url.standardizedFileURL)
        }
    }
    
    urls.forEach(processURL)
    return Array(collected)
}

struct DroppedItem: Identifiable {
    let id = UUID()
    let url: URL
    let displayName: String
    let uniformTypeDescription: String?
    let uniformTypeIdentifier: String?

    init(url: URL) {
        self.url = url
        displayName = url.lastPathComponent

        if let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
            let utType = UTType(typeIdentifier)
            uniformTypeDescription = utType?.localizedDescription ?? typeIdentifier
            uniformTypeIdentifier = typeIdentifier
        } else {
            uniformTypeDescription = nil
            uniformTypeIdentifier = nil
        }
    }

    func thumbnail(maxDimension: CGFloat = 40) -> NSImage? {
        // Use shared cache to avoid regenerating thumbnails
        return ThumbnailCache.shared.thumbnail(for: url, maxDimension: maxDimension)
    }
}

// Singleton thumbnail cache to prevent memory bloat
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private var cache: [URL: NSImage] = [:]
    private let lock = NSLock()
    private let maxCacheSize = 100 // Limit cache to prevent memory issues
    
    private init() {}
    
    func thumbnail(for url: URL, maxDimension: CGFloat) -> NSImage? {
        lock.lock()
        defer { lock.unlock() }
        
        // Return cached if available
        if let cached = cache[url] {
            return cached
        }
        
        // Generate thumbnail efficiently using CGImageSource (doesn't load full image into memory)
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension * 2 // 2x for retina
              ] as CFDictionary) else {
            return nil
        }
        
        let thumbnail = NSImage(cgImage: cgImage, size: NSSize(width: maxDimension, height: maxDimension))
        
        // Cache with size limit (LRU eviction)
        if cache.count >= maxCacheSize {
            // Remove first (oldest) item
            if let firstKey = cache.keys.first {
                cache.removeValue(forKey: firstKey)
            }
        }
        cache[url] = thumbnail
        
        return thumbnail
    }
    
    func clearCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}

enum DropError: LocalizedError {
    case noUsableFiles
    case securityScopedResourceDenied
    case fileAccessFailed(URL)

    var errorDescription: String? {
        switch self {
        case .noUsableFiles:
            return "Drag a supported image file to get started."
        case .securityScopedResourceDenied:
            return "macOS denied access to the dropped file."
        case .fileAccessFailed(let url):
            return "Could not access \(url.lastPathComponent)."
        }
    }
}

enum ConversionJobStatus: Equatable {
    case pending
    case inProgress(step: ConversionStage)
    case completed(ConversionResult)
    case failed(String)
}

struct ConversionJob: Identifiable {
    let id = UUID()
    let item: DroppedItem
    var status: ConversionJobStatus = .pending
}

struct ConversionSummary: Equatable {
    let totalFiles: Int
    let completedCount: Int
    let failedCount: Int
    let totalOriginalSize: Int64
    let totalOutputSize: Int64
    let duration: TimeInterval
    
    var totalSizeDelta: Int64 {
        totalOutputSize - totalOriginalSize
    }
    
    var percentChange: Double {
        guard totalOriginalSize > 0 else { return 0 }
        let delta = Double(totalOutputSize - totalOriginalSize)
        return delta / Double(totalOriginalSize) * 100
    }
    
    var isSmaller: Bool {
        totalOutputSize <= totalOriginalSize
    }
    
    var averageTimePerFile: TimeInterval {
        guard totalFiles > 0 else { return 0 }
        return duration / Double(totalFiles)
    }
}
