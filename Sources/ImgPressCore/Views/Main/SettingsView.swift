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
            GeneralSettingsTab(manager: manager)
          case .presets:
            PresetsSettingsTab(
              manager: manager,
              editingPresetId: $editingPresetId,
              newPresetForm: $newPresetForm,
              presetName: $presetName,
              presetDescription: $presetDescription,
              presetIcon: $presetIcon,
              presetForm: $presetForm,
              onStartNewPreset: startNewPreset,
              onStartEditingPreset: startEditingPreset,
              onCancelEditing: cancelEditing,
              onSavePreset: savePreset,
              onDeletePreset: deletePreset
            )
          }
        }
        .padding(20)
      }
    }
    .appBackground()
    .frame(width: 420, height: 600)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .onAppear {
      if let initialForm = initialPresetForm {
        selectedTab = .presets
        startNewPreset(with: initialForm)
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
