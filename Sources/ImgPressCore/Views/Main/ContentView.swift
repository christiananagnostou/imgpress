import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingSettings = false
    @State private var showingSavePreset = false

    // Limit number of jobs displayed to prevent performance issues with large batches
    private static let displayLimit = 50

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            if appState.isImporting {
                importBanner
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ScrollViewReader { scrollProxy in
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .onChange(of: appState.conversionSummary) { _, newValue in
                    if newValue != nil {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            scrollProxy.scrollTo("conversionSummary", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            footer
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
        }
        .appBackground()
        .frame(width: 420, height: 600)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.isImporting)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.jobs.isEmpty)
        .sheet(isPresented: $showingSettings) {
            SettingsView(manager: appState.presetManager)
        }
        .sheet(isPresented: $showingSavePreset) {
            PresetEditorSheet(
                manager: appState.presetManager,
                editingPreset: nil,
                initialForm: appState.conversionForm
            ) { name, description, icon, form in
                appState.presetManager.createPreset(
                    name: name, description: description, icon: icon, form: form)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            // App icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "camera.aperture")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("ImgPress")
                    .font(.title3.weight(.bold))
                Text("Image Optimizer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Settings button
            Button {
                showingSettings.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color.secondary.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }

    private var importBanner: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.importStatusMessage ?? "Scanning…")
                    .font(.subheadline.weight(.medium))
                if appState.importFoundCount > 0 {
                    Text("\(appState.importFoundCount) image(s) found")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var jobsPanel: some View {
        VStack(spacing: 16) {
            // Modern preset selector
            PresetSelector(
                appState: appState,
                presetManager: appState.presetManager,
                showingSavePreset: $showingSavePreset
            )

            // Conversion form controls (format, quality, metadata, advanced options)
            ConversionFormControls(
                form: binding(for: \.self),
                onBrowseDirectory: { appState.browseForOutputDirectory() }
            )

            Divider()
                .padding(.vertical, 4)

            // Convert button - positioned just above file list
            convertButton

            // Files section - always visible, shows conversion progress
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(
                        "\(appState.jobs.count) File\(appState.jobs.count == 1 ? "" : "s")",
                        systemImage: "photo.stack"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                    Spacer()

                    // Show progress during conversion
                    if appState.isConverting {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                            if let status = appState.conversionStatusMessage {
                                Text(status)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            // Playback controls
                            HStack(spacing: 4) {
                                // Pause/Resume button
                                Button {
                                    if appState.isPaused {
                                        appState.resumeConversion()
                                    } else {
                                        appState.pauseConversion()
                                    }
                                } label: {
                                    Image(
                                        systemName: appState.isPaused ? "play.fill" : "pause.fill"
                                    )
                                    .font(.system(size: 10))
                                    .frame(width: 18, height: 18)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help(appState.isPaused ? "Resume" : "Pause")

                                // Stop button
                                Button {
                                    appState.stopConversion()
                                } label: {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 10))
                                        .frame(width: 18, height: 18)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help("Stop")
                            }
                        }
                    } else if appState.jobs.count > 1 {
                        Button {
                            appState.jobs.removeAll()
                        } label: {
                            Text("Clear All")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }

                // Horizontal scrolling file list - compact and smooth
                ScrollViewReader { scrollProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Only show first items for performance, rest on demand
                            let itemsToShow = appState.jobs.prefix(Self.displayLimit)

                            ForEach(Array(itemsToShow)) { job in
                                jobRow(for: job)
                                    .id(job.id)
                            }

                            // Show "X more" indicator if there are hidden items
                            if appState.jobs.count > Self.displayLimit {
                                VStack(spacing: 4) {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                    Text("+\(appState.jobs.count - Self.displayLimit) more")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 100, height: 64)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.secondary.opacity(0.03))
                                )
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 2)
                    }
                    .frame(height: 72)
                    .onChange(of: appState.jobs.map { $0.status }) {
                        // Auto-scroll to the first in-progress job with smooth spring animation
                        if let inProgressJob = appState.jobs.prefix(Self.displayLimit).first(
                            where: {
                                if case .inProgress = $0.status { return true }
                                return false
                            })
                        {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                scrollProxy.scrollTo(inProgressJob.id, anchor: .center)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        appState.isConverting
                            ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.08),
                        lineWidth: appState.isConverting ? 1.5 : 1
                    )
            )

            // Status/Results - shown below the file list
            if let summary = appState.conversionSummary {
                conversionSummaryView(summary)
                    .id("conversionSummary")
            } else if let result = appState.conversionResult, appState.jobs.count == 1 {
                conversionResultView(result)
            }
        }
    }

    private func jobRow(for job: ConversionJob) -> some View {
        HStack(spacing: 8) {
            // Thumbnail
            thumbnail(for: job.item)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            statusBorderColor(for: job.status),
                            lineWidth: statusBorderWidth(for: job.status)
                        )
                )

            // File info - fixed width to prevent jittering
            VStack(alignment: .leading, spacing: 3) {
                Text(job.item.displayName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: 110, alignment: .leading)

                HStack(spacing: 4) {
                    statusBadge(for: job.status)
                        .frame(width: 12, height: 12)

                    // Fixed width for status text to prevent jittering
                    Text(statusSubtitle(for: job))
                        .font(.system(size: 9.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: 90, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(width: 180, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(statusBackgroundColor(for: job.status))
        )
    }

    private func statusBorderColor(for status: ConversionJobStatus) -> Color {
        switch status {
        case .inProgress:
            return Color.accentColor.opacity(0.4)
        case .completed:
            return Color.green.opacity(0.3)
        case .failed:
            return Color.red.opacity(0.4)
        default:
            return Color.clear
        }
    }

    private func statusBorderWidth(for status: ConversionJobStatus) -> CGFloat {
        switch status {
        case .inProgress:
            return 1.5
        case .completed, .failed:
            return 1
        default:
            return 0
        }
    }

    private func statusBackgroundColor(for status: ConversionJobStatus) -> Color {
        switch status {
        case .inProgress:
            return Color.accentColor.opacity(0.06)
        case .completed:
            return Color.green.opacity(0.06)
        case .failed:
            return Color.red.opacity(0.06)
        default:
            return Color.secondary.opacity(0.03)
        }
    }

    private var convertButton: some View {
        Button {
            appState.queueConversion()
        } label: {
            HStack(spacing: 8) {
                if appState.isConverting {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                    Text("Converting…")
                        .font(.subheadline.weight(.medium))
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.subheadline)
                    Text("Convert All")
                        .font(.subheadline.weight(.medium))
                }
            }
            .foregroundStyle(appState.isConverting ? .secondary : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(convertButtonBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        appState.isConverting
                            ? Color.secondary.opacity(0.15)
                            : Color.accentColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(appState.isConverting)
        .animation(.easeInOut(duration: 0.2), value: appState.isConverting)
    }

    private var convertButtonBackground: LinearGradient {
        if appState.isConverting {
            return LinearGradient(
                colors: [Color.secondary.opacity(0.06), Color.secondary.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.12),
                    Color.accentColor.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var conversionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let result = appState.conversionResult {
                conversionResultView(result)
            } else if let status = appState.conversionStatusMessage {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text(status)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.secondary.opacity(0.06))
                )
            }
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.75), value: appState.conversionResult != nil)
    }

    private func conversionSummaryView(_ summary: ConversionSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: summary.isSmaller ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(summary.isSmaller ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Conversion Complete")
                        .font(.headline)
                    if summary.failedCount > 0 {
                        Text("\(summary.completedCount) succeeded, \(summary.failedCount) failed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if summary.completedCount < summary.totalFiles {
                        Text("\(summary.completedCount) of \(summary.totalFiles) files converted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(
                            "All \(summary.totalFiles) file\(summary.totalFiles == 1 ? "" : "s") converted"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Duration badge
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(formatDuration(summary.duration))
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                    Text("\(String(format: "%.1f", summary.averageTimePerFile))s avg")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()

            // Size statistics with percentage change
            HStack(spacing: 20) {
                SizeComparisonView(
                    originalSize: summary.totalOriginalSize,
                    outputSize: summary.totalOutputSize,
                    isSmaller: summary.isSmaller
                )

                PercentChangeBadge(
                    percentChange: summary.percentChange,
                    sizeDelta: summary.totalSizeDelta,
                    isSmaller: summary.isSmaller
                )
            }

            Button {
                appState.revealLatestOutput()
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                    Text("Show All in Finder")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
            }
            .buttonStyle(.bordered)
        }
        .resultContainer(isSmaller: summary.isSmaller)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }

    private func conversionResultView(_ result: ConversionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.isSmaller ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.title3)
                    .foregroundStyle(result.isSmaller ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Conversion Complete")
                        .font(.headline)
                    Text(result.isSmaller ? "File size reduced" : "File size increased")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            HStack(spacing: 20) {
                SizeComparisonView(
                    originalSize: result.originalSize,
                    outputSize: result.outputSize,
                    isSmaller: result.isSmaller
                )

                PercentChangeBadge(
                    percentChange: result.percentChange,
                    sizeDelta: result.sizeDelta,
                    isSmaller: result.isSmaller
                )
            }

            Button {
                appState.revealLatestOutput()
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                    Text("Show in Finder")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
            }
            .buttonStyle(.bordered)
        }
        .resultContainer(isSmaller: result.isSmaller)
    }

    @ViewBuilder
    private func thumbnail(for item: DroppedItem) -> some View {
        if let image = item.thumbnail(maxDimension: 96) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "photo.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48, height: 48)
        }
    }

    private func statusSubtitle(for job: ConversionJob) -> String {
        switch job.status {
        case .pending:
            return "Ready to convert"
        case .inProgress(let step):
            return step.rawValue
        case .completed(let result):
            let formattedSize = Formatters.byteCount.string(fromByteCount: result.outputSize)
            return "✓ \(formattedSize)"
        case .failed(let message):
            return "✗ \(message)"
        }
    }

    @ViewBuilder
    private func statusBadge(for status: ConversionJobStatus) -> some View {
        switch status {
        case .pending:
            Image(systemName: "circle.dashed")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        case .inProgress:
            ProgressView()
                .controlSize(.mini)
                .scaleEffect(0.85)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.red)
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text("Oops!")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            // Large drop zone illustration
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("Drop Images Here")
                        .font(.title3.weight(.semibold))

                    Text(
                        "Drag images or folders onto this area\nor the menu bar icon to get started"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                }
            }

            Spacer()

            // Tips section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("Quick Tips")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    TipRow(icon: "folder.fill", text: "Drop entire folders for batch processing")
                    TipRow(icon: "wand.and.stars", text: "Use presets for common workflows")
                    TipRow(
                        icon: "slider.horizontal.3", text: "Fine-tune quality and resize settings")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.04))
            )
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDropProviders(providers)
            return true
        }
    }

    private func handleDropProviders(_ providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []

            for provider in providers {
                if let url = try? await loadURL(from: provider) {
                    urls.append(url)
                }
            }

            if !urls.isEmpty {
                await MainActor.run {
                    appState.register(drop: urls)
                }
            }
        }
    }

    private func loadURL(from provider: NSItemProvider) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let data = item as? Data,
                    let url = URL(dataRepresentation: data, relativeTo: nil)
                {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            // Version info
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("v1.0 alpha")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Quit button
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power").font(.caption)
                    Text("Quit").font(.caption)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Quit ImgPress")
        }
    }

    private func binding<T>(for keyPath: WritableKeyPath<ConversionForm, T>) -> Binding<T> {
        Binding(
            get: { self.appState.conversionForm[keyPath: keyPath] },
            set: { self.appState.conversionForm[keyPath: keyPath] = $0 }
        )
    }
}
