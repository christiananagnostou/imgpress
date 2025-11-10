import Foundation
import Testing

@testable import ImgPressCore

@Suite("PresetManager Tests")
@MainActor
struct PresetManagerTests {

  // MARK: - Test Utilities

  private func makeTestDefaults() -> UserDefaults {
    let suiteName = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    return defaults
  }

  private func makeTestForm(quality: Double = 80) -> ConversionForm {
    ConversionForm(
      format: .jpeg,
      quality: quality,
      preserveMetadata: false,
      resizePercent: 50,
      outputDirectoryPath: "",
      filenameSuffix: "_test"
    )
  }

  // MARK: - Initialization Tests

  @Test("PresetManager initializes with empty presets")
  func initializesEmpty() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    #expect(manager.presets.isEmpty)
    #expect(manager.autoApplyFirstPreset == false)
  }

  @Test("PresetManager loads persisted presets on init")
  func loadsPersisted() {
    let defaults = makeTestDefaults()
    let preset = Preset(
      name: "Test",
      description: "Test preset",
      icon: "star.fill",
      format: .jpeg,
      qualityPercent: 80,
      resizePercent: 50,
      preserveMetadata: false
    )
    let encoded = try! Coders.jsonEncoder.encode([preset])
    defaults.set(encoded, forKey: "userPresets")

    let manager = PresetManager(userDefaults: defaults)
    #expect(manager.presets.count == 1)
    #expect(manager.presets.first?.name == "Test")
  }

  @Test("PresetManager loads auto-apply setting on init")
  func loadsAutoApply() {
    let defaults = makeTestDefaults()
    defaults.set(true, forKey: "autoApplyFirstPreset")

    let manager = PresetManager(userDefaults: defaults)
    #expect(manager.autoApplyFirstPreset == true)
  }

  // MARK: - CRUD Tests

  @Test("createPreset adds preset to array")
  func createPreset() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    let form = makeTestForm()

    manager.createPreset(
      name: "Web Optimize", description: "Best for web", icon: "globe", form: form)

    #expect(manager.presets.count == 1)
    #expect(manager.presets.first?.name == "Web Optimize")
    #expect(manager.presets.first?.description == "Best for web")
    #expect(manager.presets.first?.icon == "globe")
  }

  @Test("createPreset persists to UserDefaults")
  func createPresetPersists() {
    let defaults = makeTestDefaults()
    let manager = PresetManager(userDefaults: defaults)

    manager.createPreset(name: "Test", description: "Test desc", icon: "star", form: makeTestForm())

    let data = defaults.data(forKey: "userPresets")
    #expect(data != nil)
    let decoded = try! Coders.jsonDecoder.decode([Preset].self, from: data!)
    #expect(decoded.count == 1)
  }

  @Test("updatePreset modifies existing preset")
  func updatePreset() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(
      name: "Original", description: "Old", icon: "circle", form: makeTestForm(quality: 50))

    let id = manager.presets.first!.id
    let newForm = makeTestForm(quality: 90)
    manager.updatePreset(id: id, name: "Updated", description: "New", icon: "square", form: newForm)

    #expect(manager.presets.count == 1)
    #expect(manager.presets.first?.name == "Updated")
    #expect(manager.presets.first?.description == "New")
    #expect(manager.presets.first?.icon == "square")
    #expect(manager.presets.first?.qualityPercent == 90)
  }

  @Test("updatePreset with invalid ID does nothing")
  func updateInvalidID() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(name: "Test", description: "Test", icon: "star", form: makeTestForm())

    let invalidID = UUID()
    manager.updatePreset(
      id: invalidID, name: "Should Not Update", description: "Nope", icon: "xmark",
      form: makeTestForm())

    #expect(manager.presets.first?.name == "Test")
  }

  @Test("deletePreset removes preset by ID")
  func deletePreset() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(name: "First", description: "1", icon: "1.circle", form: makeTestForm())
    manager.createPreset(name: "Second", description: "2", icon: "2.circle", form: makeTestForm())

    let idToDelete = manager.presets.first!.id
    manager.deletePreset(id: idToDelete)

    #expect(manager.presets.count == 1)
    #expect(manager.presets.first?.name == "Second")
  }

  @Test("deletePresets removes presets at offsets")
  func deletePresetsAtOffsets() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(name: "First", description: "1", icon: "1.circle", form: makeTestForm())
    manager.createPreset(name: "Second", description: "2", icon: "2.circle", form: makeTestForm())
    manager.createPreset(name: "Third", description: "3", icon: "3.circle", form: makeTestForm())

    manager.deletePresets(at: IndexSet([0, 2]))

    #expect(manager.presets.count == 1)
    #expect(manager.presets.first?.name == "Second")
  }

  @Test("reorderPresets moves presets correctly")
  func reorderPresets() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(name: "First", description: "1", icon: "1.circle", form: makeTestForm())
    manager.createPreset(name: "Second", description: "2", icon: "2.circle", form: makeTestForm())
    manager.createPreset(name: "Third", description: "3", icon: "3.circle", form: makeTestForm())

    manager.reorderPresets(from: IndexSet(integer: 2), to: 0)

    #expect(manager.presets[0].name == "Third")
    #expect(manager.presets[1].name == "First")
    #expect(manager.presets[2].name == "Second")
  }

  @Test("reorderPresets persists changes")
  func reorderPersists() {
    let defaults = makeTestDefaults()
    let manager = PresetManager(userDefaults: defaults)
    manager.createPreset(name: "First", description: "1", icon: "1.circle", form: makeTestForm())
    manager.createPreset(name: "Second", description: "2", icon: "2.circle", form: makeTestForm())

    manager.reorderPresets(from: IndexSet(integer: 1), to: 0)

    let newManager = PresetManager(userDefaults: defaults)
    #expect(newManager.presets[0].name == "Second")
  }

  @Test("getPreset returns preset by ID")
  func getPreset() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(name: "Test", description: "Test", icon: "star", form: makeTestForm())

    let id = manager.presets.first!.id
    let preset = manager.getPreset(id: id)

    #expect(preset != nil)
    #expect(preset?.name == "Test")
  }

  @Test("getPreset returns nil for invalid ID")
  func getInvalidPreset() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    let preset = manager.getPreset(id: UUID())
    #expect(preset == nil)
  }

  // MARK: - Auto-Apply Tests

  @Test("setAutoApply updates property and persists")
  func setAutoApply() {
    let defaults = makeTestDefaults()
    let manager = PresetManager(userDefaults: defaults)

    manager.setAutoApply(true)

    #expect(manager.autoApplyFirstPreset == true)
    #expect(defaults.bool(forKey: "autoApplyFirstPreset") == true)
  }

  @Test("getAutoApplyForm returns first preset form when enabled")
  func getAutoApplyForm() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    let form = makeTestForm(quality: 70)
    manager.createPreset(name: "Auto", description: "Auto preset", icon: "star", form: form)
    manager.setAutoApply(true)

    let result = manager.getAutoApplyForm()

    #expect(result != nil)
    #expect(result?.quality == 70)
  }

  @Test("getAutoApplyForm returns nil when disabled")
  func getAutoApplyFormDisabled() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(name: "Test", description: "Test", icon: "star", form: makeTestForm())
    manager.setAutoApply(false)

    let result = manager.getAutoApplyForm()
    #expect(result == nil)
  }

  @Test("getAutoApplyForm returns nil when no presets")
  func getAutoApplyFormEmpty() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.setAutoApply(true)

    let result = manager.getAutoApplyForm()
    #expect(result == nil)
  }

  // MARK: - Persistence Tests

  @Test("Multiple operations persist correctly")
  func multipleOperationsPersist() {
    let defaults = makeTestDefaults()
    let manager1 = PresetManager(userDefaults: defaults)

    manager1.createPreset(
      name: "First", description: "1st", icon: "1.circle", form: makeTestForm(quality: 50))
    manager1.createPreset(
      name: "Second", description: "2nd", icon: "2.circle", form: makeTestForm(quality: 60))
    manager1.createPreset(
      name: "Third", description: "3rd", icon: "3.circle", form: makeTestForm(quality: 70))
    manager1.deletePresets(at: IndexSet(integer: 1))
    manager1.setAutoApply(true)

    let manager2 = PresetManager(userDefaults: defaults)

    #expect(manager2.presets.count == 2)
    #expect(manager2.presets[0].name == "First")
    #expect(manager2.presets[1].name == "Third")
    #expect(manager2.autoApplyFirstPreset == true)
  }

  @Test("Preset IDs persist correctly")
  func presetsIDsPersist() {
    let defaults = makeTestDefaults()
    let manager1 = PresetManager(userDefaults: defaults)
    manager1.createPreset(name: "Test", description: "Test", icon: "star", form: makeTestForm())

    let originalID = manager1.presets.first!.id

    let manager2 = PresetManager(userDefaults: defaults)
    #expect(manager2.presets.first?.id == originalID)
  }

  // MARK: - Edge Cases

  @Test("Empty preset name is allowed")
  func emptyPresetName() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(name: "", description: "", icon: "star", form: makeTestForm())

    #expect(manager.presets.count == 1)
    #expect(manager.presets.first?.name == "")
  }

  @Test("Duplicate preset names are allowed")
  func duplicateNames() {
    let manager = PresetManager(userDefaults: makeTestDefaults())
    manager.createPreset(name: "Duplicate", description: "Dup", icon: "star", form: makeTestForm())
    manager.createPreset(
      name: "Duplicate", description: "Dup2", icon: "star.fill", form: makeTestForm())

    #expect(manager.presets.count == 2)
    #expect(manager.presets[0].name == "Duplicate")
    #expect(manager.presets[1].name == "Duplicate")
  }

  @Test("Preset makeForm returns correct form")
  func makeForm() {
    let preset = Preset(
      name: "Test", description: "Test desc", icon: "star", format: .jpeg, qualityPercent: 65,
      resizePercent: 50, preserveMetadata: true)

    let result = preset.makeForm()
    #expect(result.format == .jpeg)
    #expect(result.quality == 65)
    #expect(result.resizePercent == 50)
    #expect(result.preserveMetadata == true)
  }
}
