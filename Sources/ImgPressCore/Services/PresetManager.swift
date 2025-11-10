import Foundation
import SwiftUI

/// Manages user-created presets with persistence to UserDefaults
@MainActor
final class PresetManager: ObservableObject {
  @Published var presets: [Preset] = []
  @Published var autoApplyFirstPreset: Bool = false

  private let presetsKey = "userPresets"
  private let autoApplyKey = "autoApplyFirstPreset"
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    loadPresets()
    loadAutoApplySetting()
  }

  // MARK: - CRUD Operations

  func createPreset(name: String, description: String, icon: String, form: ConversionForm) {
    let preset = Preset(
      name: name,
      description: description,
      icon: icon,
      format: form.format,
      qualityPercent: form.quality,
      resizePercent: form.resizePercent,
      preserveMetadata: form.preserveMetadata
    )
    presets.append(preset)
    savePresets()
  }

  func updatePreset(id: UUID, name: String, description: String, icon: String, form: ConversionForm)
  {
    guard let index = presets.firstIndex(where: { $0.id == id }) else { return }
    presets[index] = Preset(
      id: id,
      name: name,
      description: description,
      icon: icon,
      format: form.format,
      qualityPercent: form.quality,
      resizePercent: form.resizePercent,
      preserveMetadata: form.preserveMetadata
    )
    savePresets()
  }

  func deletePreset(id: UUID) {
    presets.removeAll { $0.id == id }
    savePresets()
  }

  func deletePresets(at offsets: IndexSet) {
    presets.remove(atOffsets: offsets)
    savePresets()
  }

  func reorderPresets(from source: IndexSet, to destination: Int) {
    presets.move(fromOffsets: source, toOffset: destination)
    savePresets()
  }

  func getPreset(id: UUID) -> Preset? {
    presets.first { $0.id == id }
  }

  // MARK: - Settings

  func setAutoApply(_ enabled: Bool) {
    autoApplyFirstPreset = enabled
    userDefaults.set(enabled, forKey: autoApplyKey)
  }

  // MARK: - Persistence

  private func savePresets() {
    if let encoded = try? Coders.jsonEncoder.encode(presets) {
      userDefaults.set(encoded, forKey: presetsKey)
    }
  }

  private func loadPresets() {
    guard let data = userDefaults.data(forKey: presetsKey),
      let decoded = try? Coders.jsonDecoder.decode([Preset].self, from: data)
    else {
      presets = []
      return
    }
    presets = decoded
  }

  private func loadAutoApplySetting() {
    autoApplyFirstPreset = userDefaults.bool(forKey: autoApplyKey)
  }

  // MARK: - Auto-Apply

  func getAutoApplyForm() -> ConversionForm? {
    guard autoApplyFirstPreset, let firstPreset = presets.first else {
      return nil
    }
    return firstPreset.makeForm()
  }
}
