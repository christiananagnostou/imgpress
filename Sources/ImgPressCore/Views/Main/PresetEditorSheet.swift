import SwiftUI

struct PresetEditorSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var appState: AppState
  @ObservedObject var manager: PresetManager

  let editingPreset: Preset?
  let onSave: (String, String, String, ConversionForm) -> Void

  @State private var name: String
  @State private var description: String
  @State private var icon: String
  @State private var form: ConversionForm

  init(
    manager: PresetManager,
    editingPreset: Preset? = nil,
    initialForm: ConversionForm? = nil,
    onSave: @escaping (String, String, String, ConversionForm) -> Void
  ) {
    self.manager = manager
    self.editingPreset = editingPreset
    self.onSave = onSave

    if let preset = editingPreset {
      _name = State(initialValue: preset.name)
      _description = State(initialValue: preset.description)
      _icon = State(initialValue: preset.icon)
      _form = State(initialValue: preset.makeForm())
    } else if let initial = initialForm {
      _name = State(initialValue: "")
      _description = State(initialValue: "")
      _icon = State(initialValue: "star.fill")
      _form = State(initialValue: initial)
    } else {
      _name = State(initialValue: "")
      _description = State(initialValue: "")
      _icon = State(initialValue: "star.fill")
      _form = State(initialValue: .makeDefault())
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text(editingPreset == nil ? "New Preset" : "Edit Preset")
          .font(.title2)
          .fontWeight(.semibold)
        Spacer()
        Button("Cancel") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
      }
      .padding()

      Divider()

      ScrollView {
        VStack(spacing: 16) {
          // Preset Name
          VStack(alignment: .leading, spacing: 8) {
            Text("Preset Name")
              .font(.caption.weight(.medium))
              .foregroundStyle(.secondary)
            TextField("Enter preset name", text: $name)
              .textFieldStyle(.roundedBorder)
              .font(.caption)
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(Color.secondary.opacity(0.04))
          )

          // Preset Description
          VStack(alignment: .leading, spacing: 8) {
            Text("Description")
              .font(.caption.weight(.medium))
              .foregroundStyle(.secondary)
            TextField("Enter description", text: $description)
              .textFieldStyle(.roundedBorder)
              .font(.caption)
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(Color.secondary.opacity(0.04))
          )

          // Preset Icon
          VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
              .font(.caption.weight(.medium))
              .foregroundStyle(.secondary)
            HStack {
              TextField("SF Symbol name", text: $icon)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

              // Icon preview
              Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())
            }
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(Color.secondary.opacity(0.04))
          )

          // Reuse the exact same controls as ContentView
          ConversionFormControls(
            form: $form,
            onBrowseDirectory: { appState.browseForOutputDirectory() }
          )
        }
        .padding()
      }

      Divider()

      // Footer with Save button
      HStack {
        Spacer()
        Button(editingPreset == nil ? "Create Preset" : "Save Changes") {
          onSave(name, description, icon, form)
          dismiss()
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
      }
      .padding()
    }
    .appBackground()
    .frame(minWidth: 450, minHeight: 600)
  }
}
