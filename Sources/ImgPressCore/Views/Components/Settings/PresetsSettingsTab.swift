import SwiftUI

struct PresetsSettingsTab: View {
  @EnvironmentObject private var appState: AppState
  @ObservedObject var manager: PresetManager

  @Binding var editingPresetId: UUID?
  @Binding var newPresetForm: ConversionForm?
  @Binding var presetName: String
  @Binding var presetDescription: String
  @Binding var presetIcon: String
  @Binding var presetForm: ConversionForm

  let onStartNewPreset: (ConversionForm?) -> Void
  let onStartEditingPreset: (Preset) -> Void
  let onCancelEditing: () -> Void
  let onSavePreset: () -> Void
  let onDeletePreset: (Preset) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // New/Edit Preset Form (shown when creating or editing)
      if editingPresetId != nil || newPresetForm != nil {
        presetEditorForm
      } else {
        // Preset List
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Label("Custom Presets", systemImage: "star.fill")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.secondary)
            Spacer()
            Button {
              onStartNewPreset(nil)
            } label: {
              HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                Text("New Preset")
              }
              .font(.subheadline)
            }
            .buttonStyle(.bordered)
          }

          if manager.presets.isEmpty {
            emptyPresetsView
          } else {
            presetsList
          }
        }
      }

      Spacer()
    }
  }

  private var presetEditorForm: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(editingPresetId == nil ? "New Preset" : "Edit Preset")
          .font(.headline)
        Spacer()
        Button("Cancel") {
          onCancelEditing()
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
      }

      // Preset Metadata
      FormFieldSection {
        VStack(spacing: 12) {
          FormTextField(
            label: "Preset Name",
            placeholder: "Enter preset name",
            text: $presetName
          )

          FormTextField(
            label: "Description",
            placeholder: "Enter description",
            text: $presetDescription
          )

          FormIconPicker(label: "Icon", iconName: $presetIcon)
        }
      }

      // Conversion Settings
      ConversionFormControls(
        form: $presetForm,
        onBrowseDirectory: { appState.browseForOutputDirectory() }
      )

      // Save/Update Button
      HStack {
        Spacer()
        Button(editingPresetId == nil ? "Create Preset" : "Save Changes") {
          onSavePreset()
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(presetName.trimmingCharacters(in: .whitespaces).isEmpty)
      }
    }
  }

  private var emptyPresetsView: some View {
    VStack(spacing: 12) {
      Image(systemName: "star.slash")
        .font(.system(size: 40))
        .foregroundStyle(.tertiary)
      Text("No custom presets yet")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
      Text("Create presets to save your favorite settings")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.secondary.opacity(0.04))
    )
  }

  private var presetsList: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(manager.presets) { preset in
        PresetRow(
          preset: preset,
          showIcon: true,
          showEditButton: true,
          showDeleteButton: true,
          onEdit: {
            onStartEditingPreset(preset)
          },
          onDelete: {
            onDeletePreset(preset)
          }
        )
      }
    }
  }
}
