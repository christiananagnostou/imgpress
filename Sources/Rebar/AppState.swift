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
    @Published var conversionErrorMessage: String?
    @Published var isConverting = false

    private let conversionService: ConversionService

    init(conversionService: ConversionService = ConversionService()) {
        self.conversionService = conversionService
        let presets = ConversionPreset.defaults
        self.presets = presets
        let initialPreset = presets.first ?? ConversionPreset.defaults[0]
        self.selectedPreset = initialPreset
        self.conversionForm = initialPreset.makeForm()
    }

    func register(drop urls: [URL]) {
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

            for url in candidates {
                if FileTypeValidator.isAcceptable(url) {
                    let item = DroppedItem(url: url)
                    await MainActor.run {
                        self.jobs.append(ConversionJob(item: item))
                        self.importFoundCount += 1
                        self.importStatusMessage = "Found \(self.importFoundCount) image(s)…"
                    }
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
        conversionStatusMessage = "Converting 0/\(jobs.count)…"
        conversionErrorMessage = nil
        conversionResult = nil

        let jobsSnapshot = jobs
        let formSnapshot = conversionForm

        Task {
            var completedCount = 0
            var failedCount = 0

            for job in jobsSnapshot {
                await MainActor.run {
                    self.updateJob(job.id) { job in
                        job.status = .inProgress(step: .loadingInput)
                    }
                    self.conversionStatusMessage = "Converting \(completedCount)/\(jobsSnapshot.count)…"
                }

                do {
                    let result = try await self.conversionService.convert(
                        item: job.item,
                        form: formSnapshot,
                        progress: { stage in
                            Task { @MainActor in
                                self.updateJob(job.id) { job in
                                    job.status = .inProgress(step: stage)
                                }
                            }
                        }
                    )
                    completedCount += 1
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

            await MainActor.run {
                let summary = failedCount > 0 
                    ? "Completed \(completedCount), failed \(failedCount)"
                    : "Completed all \(completedCount) file(s)"
                self.conversionStatusMessage = summary
                self.isConverting = false
            }
        }
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
        guard let image = NSImage(contentsOf: url) else { return nil }
        return image.resized(toMaxDimension: maxDimension)
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

enum ConversionJobStatus {
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
