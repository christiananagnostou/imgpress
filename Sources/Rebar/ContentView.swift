import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            header
            if let error = appState.dropError {
                errorView(error)
            } else if let item = appState.latestDrop {
                droppedItemView(item)
            } else {
                emptyState
            }
            Spacer()
            footer
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(nsColor: NSColor.windowBackgroundColor)
                .ignoresSafeArea()
        )
    }

    private var header: some View {
        HStack {
            Label("Rebar", systemImage: "camera.aperture")
                .font(.title2.weight(.semibold))
            Spacer()
            Text("alpha")
                .font(.caption)
                .foregroundStyle(.secondary)
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

    private func droppedItemView(_ item: DroppedItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    if let uniformTypeDescription = item.uniformTypeDescription {
                        Text(uniformTypeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "photo.on.rectangle.angled")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 30))
                    .foregroundStyle(.blue)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Conversion Presets")
                    .font(.subheadline.weight(.semibold))
                presetRow(title: "Shareable JPEG", detail: "75% quality • metadata preserved")
                presetRow(title: "Transparent PNG", detail: "Lossless • metadata preserved")
                presetRow(title: "High efficiency AVIF", detail: "45% smaller • modern formats")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func presetRow(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Queue") {
                // Placeholder action for future conversion pipeline hookup.
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down.on.square.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Drag an image onto the menu bar icon to begin")
                .multilineTextAlignment(.center)
                .font(.headline)
            Text("HEIC, RAW, AVIF, and more — we’ll queue the right conversions and keep metadata intact.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
}
