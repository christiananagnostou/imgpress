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
                if isAcceptableURL(url) {
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
                    await MainActor.run {
                        self.updateJob(job.id) { job in
                            job.status = .failed(error.localizedDescription)
                        }
                    }
                }
            }

            await MainActor.run {
                self.conversionStatusMessage = "Finished \(completedCount)/\(jobsSnapshot.count) file(s)"
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
        jobs = jobs.map { current in
            guard current.id == id else { return current }
            var updated = current
            mutate(&updated)
            return updated
        }
    }

}

// MARK: - Helpers (not actor-isolated)

private func flattenURLs(_ urls: [URL]) -> [URL] {
    var collected: [URL] = []
    let fm = FileManager.default

    for url in urls {
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            if let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let fileURL as URL in enumerator {
                    collected.append(fileURL)
                }
            }
        } else {
            collected.append(url)
        }
    }

    var seen = Set<URL>()
    return collected.filter { seen.insert($0.standardizedFileURL).inserted }
}

private func isAcceptableURL(_ url: URL) -> Bool {
    guard url.isFileURL else { return false }
    guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
          let type = UTType(typeIdentifier) else {
        return false
    }

    let allowedTypes: [UTType] = [
        .image,
        .rawImage,
        .livePhoto,
        UTType("com.canon.cr2-raw-image"),
        UTType("public.heic"),
        UTType("com.canon.cr3-raw-image"),
        UTType("com.adobe.raw-image"),
        UTType("com.apple.protected-mpeg-4-audio"),
        UTType("com.apple.quicktime-image")
    ].compactMap { $0 }

    return allowedTypes.contains(where: { type.conforms(to: $0) })
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
