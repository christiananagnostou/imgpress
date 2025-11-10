import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var manager: PresetManager

  @State private var showingPresetEditor = false
  @State private var editingPreset: Preset?

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Settings")
          .font(.title2)
          .fontWeight(.semibold)
        Spacer()
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }
      .padding()

      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          // General Settings
          VStack(alignment: .leading, spacing: 12) {
            Text("General")
              .font(.headline)

            Toggle(
              "Auto-apply first preset on launch",
              isOn: Binding(
                get: { manager.autoApplyFirstPreset },
                set: { manager.setAutoApply($0) }
              )
            )
            .help("Automatically apply your first preset when the app starts")
          }

          Divider()

          // Custom Presets
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Custom Presets")
                .font(.headline)
              Spacer()
              Button {
                editingPreset = nil
                showingPresetEditor = true
              } label: {
                Label("Add Preset", systemImage: "plus")
              }
            }

            if manager.presets.isEmpty {
              VStack(spacing: 8) {
                Image(systemName: "tray")
                  .font(.largeTitle)
                  .foregroundStyle(.tertiary)
                Text("No custom presets")
                  .font(.callout)
                  .foregroundStyle(.secondary)
                Text("Create presets to save your favorite settings")
                  .font(.caption)
                  .foregroundStyle(.tertiary)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 32)
            } else {
              List {
                ForEach(manager.presets) { preset in
                  PresetRow(preset: preset) {
                    editingPreset = preset
                    showingPresetEditor = true
                  }
                }
                .onDelete { offsets in
                  manager.deletePresets(at: offsets)
                }
                .onMove { source, destination in
                  manager.reorderPresets(from: source, to: destination)
                }
              }
              .frame(height: min(CGFloat(manager.presets.count) * 44, 300))
              .scrollContentBackground(.hidden)

              Text("Drag to reorder • Swipe to delete")
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
          }
        }
        .padding()
      }
    }
    .appBackground()
    .frame(minWidth: 500, minHeight: 400)
    .sheet(isPresented: $showingPresetEditor) {
      PresetEditorSheet(
        manager: manager,
        editingPreset: editingPreset,
        initialForm: editingPreset == nil ? .makeDefault() : nil
      ) { name, description, icon, form in
        if let editing = editingPreset {
          manager.updatePreset(
            id: editing.id, name: name, description: description, icon: icon, form: form)
        } else {
          manager.createPreset(name: name, description: description, icon: icon, form: form)
        }
      }
    }
  }
}
