import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
  case general = "General"
  case presets = "Presets"

  var id: String { rawValue }
  var icon: String {
    switch self {
    case .general: return "gearshape"
    case .presets: return "star.fill"
    }
  }
}

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var appState: AppState
  @ObservedObject var manager: PresetManager

  @State private var selectedTab: SettingsTab = .general
  @State private var editingPresetId: UUID?
  @State private var newPresetForm: ConversionForm?

  // Form state for editing/creating presets
  @State private var presetName = ""
  @State private var presetDescription = ""
  @State private var presetIcon = "star.fill"
  @State private var presetForm = ConversionForm.makeDefault()

  // Initialize with optional preset form for "Save as Preset" flow
  let initialPresetForm: ConversionForm?

  init(manager: PresetManager, initialPresetForm: ConversionForm? = nil) {
    self.manager = manager
    self.initialPresetForm = initialPresetForm
  }

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

      // Tab Selector
      HStack {
        ModernSegmentedControl(
          selection: $selectedTab,
          options: SettingsTab.allCases,
          titleProvider: { $0.rawValue },
          iconProvider: { $0.icon }
        )
        .frame(maxWidth: 320)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      Divider()

      // Tab Content
      ScrollView {
        Group {
          switch selectedTab {
          case .general:
            generalTabContent
          case .presets:
            presetsTabContent
          }
        }
        .padding(20)
      }
    }
    .appBackground()
    .frame(width: 520, height: 580)
    .onAppear {
      if let initialForm = initialPresetForm {
        selectedTab = .presets
        startNewPreset(with: initialForm)
      }
    }
  }

  private var generalTabContent: some View {
    VStack(alignment: .leading, spacing: 16) {
      FormFieldSection(title: "Startup", icon: "bolt.circle") {
        Toggle(
          isOn: Binding(
            get: { manager.autoApplyFirstPreset },
            set: { manager.setAutoApply($0) }
          )
        ) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Auto-apply first preset")
              .font(.subheadline)
            Text("Apply your first preset automatically when the app starts")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .toggleStyle(.switch)
      }

      FormFieldSection(title: "About", icon: "info.circle") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Version")
              .foregroundStyle(.secondary)
            Spacer()
            Text("1.0 alpha")
              .font(.caption.monospacedDigit())
          }
          .font(.subheadline)

          Divider()

          HStack {
            Text("Build")
              .foregroundStyle(.secondary)
            Spacer()
            Text("2025.11.09")
              .font(.caption.monospacedDigit())
          }
          .font(.subheadline)
        }
      }

      Spacer()
    }
  }

  private var presetsTabContent: some View {
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
              startNewPreset()
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
          cancelEditing()
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
          savePreset()
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
        presetRow(for: preset)
      }

      Text("Swipe left to delete presets")
        .font(.caption)
        .foregroundStyle(.tertiary)
        .padding(.top, 4)
    }
  }

  private func presetRow(for preset: Preset) -> some View {
    HStack(spacing: 12) {
      // Icon
      Image(systemName: preset.icon)
        .font(.title3)
        .foregroundStyle(Color.accentColor)
        .frame(width: 32, height: 32)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(Circle())

      // Info
      VStack(alignment: .leading, spacing: 4) {
        Text(preset.name)
          .font(.subheadline.weight(.medium))

        HStack(spacing: 8) {
          Label(preset.format.displayName, systemImage: "photo")
          if preset.format.supportsQuality {
            Text("\(Int(preset.qualityPercent))% quality")
          }
          if preset.resizePercent != 100 {
            Text("\(Int(preset.resizePercent))% scale")
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      Spacer()

      // Edit button
      Button {
        startEditingPreset(preset)
      } label: {
        Image(systemName: "pencil.circle.fill")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.secondary.opacity(0.04))
    )
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      Button(role: .destructive) {
        deletePreset(preset)
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }

  // MARK: - Actions

  private func startNewPreset(with form: ConversionForm? = nil) {
    editingPresetId = nil
    newPresetForm = form ?? .makeDefault()
    presetName = ""
    presetDescription = ""
    presetIcon = "star.fill"
    presetForm = form ?? .makeDefault()
  }

  private func startEditingPreset(_ preset: Preset) {
    editingPresetId = preset.id
    newPresetForm = nil
    presetName = preset.name
    presetDescription = preset.description
    presetIcon = preset.icon
    presetForm = preset.makeForm()
  }

  private func cancelEditing() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      editingPresetId = nil
      newPresetForm = nil
    }
  }

  private func savePreset() {
    if let editingId = editingPresetId {
      manager.updatePreset(
        id: editingId,
        name: presetName,
        description: presetDescription,
        icon: presetIcon,
        form: presetForm
      )
    } else {
      manager.createPreset(
        name: presetName,
        description: presetDescription,
        icon: presetIcon,
        form: presetForm
      )
    }
    cancelEditing()
  }

  private func deletePreset(_ preset: Preset) {
    if let index = manager.presets.firstIndex(where: { $0.id == preset.id }) {
      manager.deletePresets(at: IndexSet(integer: index))
    }
  }
}
