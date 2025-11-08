import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            header
            if appState.isImporting {
                importBanner
            }
            ScrollView {
                VStack(spacing: 16) {
                    if let error = appState.dropError {
                        errorView(error)
                    } else if !appState.jobs.isEmpty {
                        jobsPanel
                    } else {
                        emptyState
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxHeight: 360)
            footer
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(nsColor: NSColor.windowBackgroundColor)
                .ignoresSafeArea()
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Label("Rebar", systemImage: "camera.aperture")
                .font(.title2.weight(.semibold))
            Spacer()
            Text("alpha")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var importBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(appState.importStatusMessage ?? "Scanning…")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if appState.importFoundCount > 0 {
                Text("\(appState.importFoundCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Job Panel

    private var jobsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            jobSummary
            jobList
            presetSelector
            conversionControls
            conversionStatusSection
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var jobSummary: some View {
        HStack(spacing: 16) {
            thumbnailStack(for: appState.jobs.prefix(3))
            VStack(alignment: .leading, spacing: 4) {
                if appState.jobs.count == 1, let job = appState.jobs.first {
                    Text(job.item.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    if let desc = job.item.uniformTypeDescription {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("\(appState.jobs.count) files ready")
                        .font(.headline)
                    Text("Adjust the options below and convert everything in one go.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var jobList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(appState.jobs) { job in
                        HStack(spacing: 12) {
                            thumbnail(for: job.item)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(job.item.displayName)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text(statusSubtitle(for: job))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            statusBadge(for: job.status)
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.trailing, 2)
            }
            .frame(maxHeight: 180)
        }
    }

    // MARK: - Presets & Controls

    private var presetSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversion Presets")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appState.presets) { preset in
                        Button {
                            appState.selectPreset(preset)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Label(preset.name, systemImage: preset.hero)
                                    .labelStyle(.titleAndIcon)
                                    .font(.subheadline.weight(.semibold))
                                Text(preset.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(minWidth: 160, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(appState.selectedPreset == preset ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(appState.selectedPreset == preset ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var conversionControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customization")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Format", selection: formatBinding) {
                ForEach(ImageFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)

            if appState.conversionForm.format.supportsQuality {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Quality")
                        Spacer()
                        Text("\(Int(appState.conversionForm.quality))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: qualityBinding, in: 30...100, step: 1)
                }
            } else {
                Label("Lossless codec – quality slider disabled", systemImage: "aqi.medium")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: preserveMetadataBinding) {
                Label("Preserve metadata (Exif, GPS)", systemImage: "tag")
            }

            Toggle(isOn: resizeEnabledBinding.animation()) {
                Label("Resize", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
            }

            if appState.conversionForm.resizeEnabled {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Scale")
                        Spacer()
                        Text("\(Int(appState.conversionForm.resizePercent))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: resizePercentBinding, in: 20...150, step: 5)
                        .tint(.orange)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Output directory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField("Path", text: outputDirectoryBinding)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse…") {
                        appState.browseForOutputDirectory()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Filename suffix")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("_rebar", text: filenameSuffixBinding)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let status = appState.conversionStatusMessage {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let error = appState.conversionErrorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                Spacer()
                Button {
                    appState.queueConversion()
                } label: {
                    Label(appState.isConverting ? "Converting…" : "Convert & Queue", systemImage: "bolt.fill")
                }
                .disabled(appState.isConverting)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var conversionStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let result = appState.conversionResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest output")
                        .font(.subheadline.weight(.semibold))
                    HStack {
                        Label("Original: \(ByteCountFormatter.string(fromByteCount: result.originalSize, countStyle: .file))", systemImage: "doc")
                        Spacer()
                        Label("New: \(ByteCountFormatter.string(fromByteCount: result.outputSize, countStyle: .file))", systemImage: "doc.badge.plus")
                    }
                    .font(.caption)
                    HStack {
                        let percent = abs(result.percentChange)
                        let formatted = String(format: "%.1f", percent)
                        let changeText = result.isSmaller ? "Reduction" : "Increase"
                        let color: Color = result.isSmaller ? .green : .orange
                        Text("\(changeText): \(formatted)% (\(ByteCountFormatter.string(fromByteCount: abs(result.sizeDelta), countStyle: .file)))")
                            .font(.caption)
                            .foregroundStyle(color)
                        Spacer()
                        Button {
                            appState.revealLatestOutput()
                        } label: {
                            Label("Show in Finder", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(result.isSmaller ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                )
            } else if let error = appState.conversionErrorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helpers

    private func thumbnailStack<S: Sequence>(for jobs: S) -> some View where S.Element == ConversionJob {
        let array = Array(jobs)
        return HStack(spacing: -12) {
            ForEach(Array(array.enumerated()), id: \.element.id) { index, job in
                thumbnail(for: job.item)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                    )
                    .zIndex(Double(array.count - index))
            }
        }
        .frame(height: 48)
    }

    @ViewBuilder
    private func thumbnail(for item: DroppedItem) -> some View {
        if let image = item.thumbnail(maxDimension: 48) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48, height: 48)
        }
    }

    private func statusSubtitle(for job: ConversionJob) -> String {
        switch job.status {
        case .pending:
            return "Queued"
        case .inProgress(let step):
            return step.rawValue
        case .completed(let result):
            let formatter = ByteCountFormatter.string(fromByteCount: result.outputSize, countStyle: .file)
            return "Done • \(formatter)"
        case .failed(let message):
            return message
        }
    }

    @ViewBuilder
    private func statusBadge(for status: ConversionJobStatus) -> some View {
        switch status {
        case .pending:
            Label("Pending", systemImage: "clock")
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
        case .inProgress(let step):
            VStack(spacing: 4) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                Text(step.shortLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(.red)
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Drop failed", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.headline)
            Text(error.localizedDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(0.06))
                VStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                    Text("Drop images or folders onto the Rebar icon")
                        .font(.headline)
                    Text("We’ll queue them here for batch optimization.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, minHeight: 160)

            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Tips")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Label("Use folders for big batches", systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Presets + resizing apply to all", systemImage: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Bindings

    private var formatBinding: Binding<ImageFormat> {
        Binding {
            appState.conversionForm.format
        } set: { newValue in
            appState.conversionForm.format = newValue
        }
    }

    private var qualityBinding: Binding<Double> {
        Binding {
            appState.conversionForm.quality
        } set: { newValue in
            appState.conversionForm.quality = newValue
        }
    }

    private var preserveMetadataBinding: Binding<Bool> {
        Binding {
            appState.conversionForm.preserveMetadata
        } set: { newValue in
            appState.conversionForm.preserveMetadata = newValue
        }
    }

    private var resizeEnabledBinding: Binding<Bool> {
        Binding {
            appState.conversionForm.resizeEnabled
        } set: { newValue in
            appState.conversionForm.resizeEnabled = newValue
        }
    }

    private var resizePercentBinding: Binding<Double> {
        Binding {
            appState.conversionForm.resizePercent
        } set: { newValue in
            appState.conversionForm.resizePercent = newValue
        }
    }

    private var outputDirectoryBinding: Binding<String> {
        Binding {
            appState.conversionForm.outputDirectoryPath
        } set: { newValue in
            appState.conversionForm.outputDirectoryPath = newValue
        }
    }

    private var filenameSuffixBinding: Binding<String> {
        Binding {
            appState.conversionForm.filenameSuffix
        } set: { newValue in
            appState.conversionForm.filenameSuffix = newValue
        }
    }
}
