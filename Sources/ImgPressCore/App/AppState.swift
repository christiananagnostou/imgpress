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
    @Published var presets: [Preset]
    @Published var selectedPreset: Preset
    @Published var conversionForm: ConversionForm
    @Published var conversionStatusMessage: String?
    @Published var conversionResult: ConversionResult?
    @Published var conversionSummary: ConversionSummary?
    @Published var conversionErrorMessage: String?
    @Published var isConverting = false
    @Published var isPaused = false
    @Published var shouldStop = false

    let presetManager: PresetManager

    private let conversionService: ConversionService
    private var conversionTask: Task<Void, Never>?

    init(
        conversionService: ConversionService = ConversionService(),
        presetManager: PresetManager = PresetManager()
    ) {
        self.conversionService = conversionService
        self.presetManager = presetManager
        self.presets = Preset.defaults

        // Determine initial preset based on auto-apply setting
        let initialPreset: Preset
        if presetManager.autoApplyFirstPreset, let firstCustom = presetManager.presets.first {
            // Auto-apply enabled: use first custom preset if available
            initialPreset = firstCustom
        } else {
            // Auto-apply disabled: always use first default preset
            initialPreset = Preset.defaults[0]
        }

        self.selectedPreset = initialPreset
        self.conversionForm = initialPreset.makeForm()
    }

    func register(drop urls: [URL]) {
        ThumbnailCache.shared.clearCache()

        jobs = []
        dropError = nil
        isImporting = true
        importFoundCount = 0
        importStatusMessage = "Scanning…"
        conversionStatusMessage = nil
        conversionErrorMessage = nil
        conversionResult = nil
        conversionSummary = nil

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let candidates = Self.flattenURLs(urls)

            var newJobs: [ConversionJob] = []
            var processedCount = 0
            let batchSize = 20

            for url in candidates {
                if FileTypeValidator.isAcceptable(url) {
                    let item = DroppedItem(url: url)
                    newJobs.append(ConversionJob(item: item))
                    processedCount += 1

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

    func selectPreset(_ preset: Preset) {
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
        conversionSummary = nil

        let jobsSnapshot = jobs
        let formSnapshot = conversionForm
        let startTime = Date()

        conversionTask = Task {
            var completedCount = 0
            var failedCount = 0
            var totalOriginalSize: Int64 = 0
            var totalOutputSize: Int64 = 0

            for job in jobsSnapshot {
                // Since AppState is @MainActor, we can access properties directly
                if shouldStop { break }

                while isPaused && !shouldStop {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }

                if shouldStop { break }

                updateJob(job.id) { job in
                    job.status = .inProgress(step: .loadingInput)
                }

                do {
                    let result = try await self.conversionService.convert(
                        item: job.item,
                        form: formSnapshot,
                        progress: nil
                    )
                    completedCount += 1
                    totalOriginalSize += result.originalSize
                    totalOutputSize += result.outputSize

                    updateJob(job.id) { job in
                        job.status = .completed(result)
                    }
                    conversionStatusMessage =
                        "Converting \(completedCount)/\(jobsSnapshot.count)…"
                    conversionResult = result
                } catch {
                    failedCount += 1
                    updateJob(job.id) { job in
                        job.status = .failed(error.localizedDescription)
                    }
                }
            }

            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)

            let summary =
                shouldStop
                ? "Stopped: \(completedCount) completed, \(jobsSnapshot.count - completedCount - failedCount) skipped"
                : (failedCount > 0
                    ? "Completed \(completedCount), failed \(failedCount)"
                    : "Completed all \(completedCount) file(s)")
            conversionStatusMessage = summary
            if completedCount > 0 {
                conversionSummary = ConversionSummary(
                    totalFiles: jobsSnapshot.count,
                    completedCount: completedCount,
                    failedCount: failedCount,
                    totalOriginalSize: totalOriginalSize,
                    totalOutputSize: totalOutputSize,
                    duration: duration
                )
            }
            isConverting = false
            isPaused = false
            shouldStop = false
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

    // MARK: - File Processing

    private nonisolated static func flattenURLs(_ urls: [URL]) -> [URL] {
        let fm = FileManager.default
        var collected = Set<URL>()
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey]

        func processURL(_ url: URL) {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return }

            if isDir.boolValue {
                guard
                    let enumerator = fm.enumerator(
                        at: url,
                        includingPropertiesForKeys: resourceKeys,
                        options: [.skipsHiddenFiles]
                    )
                else { return }

                for case let fileURL as URL in enumerator {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                        resourceValues.isRegularFile == true
                    {
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

}
