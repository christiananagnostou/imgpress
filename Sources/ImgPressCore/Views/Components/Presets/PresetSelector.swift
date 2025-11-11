import SwiftUI

/// Modern preset selector with segmented control for default/custom presets
/// and grid-based selection for better visual hierarchy
struct PresetSelector: View {
  @ObservedObject var appState: AppState
  @ObservedObject var presetManager: PresetManager
  let onSavePreset: () -> Void

  @State private var isExpanded: Bool = true
  @State private var selectedTab: PresetTab = .defaults
  @State private var selectedCustomPresetId: UUID?

  enum PresetTab: Equatable {
    case defaults, custom
  }

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(spacing: 14) {
        // Modern tab selector - always visible
        ModernSegmentedControl(
          selection: $selectedTab,
          options: [
            (value: .defaults, title: "Defaults", icon: "sparkles"),
            (value: .custom, title: "Custom", icon: "star.fill"),
          ]
        )

        // Preset content based on selected tab
        if selectedTab == .defaults {
          defaultPresetsGrid
        } else {
          customPresetsList
        }

        // Save current settings button
        Divider()

        Button {
          onSavePreset()
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
              .font(.caption)
            Text("Save Current Settings")
              .font(.caption.weight(.medium))
          }
          .foregroundStyle(Color.accentColor)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color.accentColor.opacity(0.1))
          )
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 12)
    } label: {
      HStack {
        Label("Quick Presets", systemImage: "wand.and.stars")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)

        Spacer()

        // Active preset indicator when collapsed
        if !isExpanded {
          HStack(spacing: 6) {
            Circle()
              .fill(Color.accentColor)
              .frame(width: 6, height: 6)

            Text(activePresetName)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .disclosureGroupStyle(FullWidthDisclosureStyle())
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.secondary.opacity(0.04))
    )
    .animation(.spring(response: 0.3), value: selectedTab)
    .animation(.spring(response: 0.3), value: isExpanded)
    .onChange(of: presetManager.presets.count) { oldCount, newCount in
      // Auto-select newly created preset
      if newCount > oldCount, let newest = presetManager.presets.last {
        let newestForm = newest.makeForm()
        if newestForm.format == appState.conversionForm.format
          && newestForm.quality == appState.conversionForm.quality
          && newestForm.resizePercent == appState.conversionForm.resizePercent
        {
          selectedCustomPresetId = newest.id
          selectedTab = .custom
        }
      }
    }
  }

  private var activePresetName: String {
    // Check if a custom preset is active by ID
    if let selectedId = selectedCustomPresetId,
      let customPreset = presetManager.presets.first(where: { $0.id == selectedId })
    {
      return "Custom: \(customPreset.name)"
    }

    // Otherwise show default preset
    return appState.selectedPreset.name
  }

  private var defaultPresetsGrid: some View {
    VStack(spacing: 8) {
      ForEach(appState.presets) { preset in
        PresetCard(
          title: preset.name,
          subtitle: presetSubtitle(for: preset),
          icon: preset.icon,
          iconColor: .accentColor,
          rightContent: .badge(preset.format.displayName.uppercased()),
          isSelected: isDefaultPresetSelected(preset),
          action: {
            appState.selectPreset(preset)
            selectedCustomPresetId = nil  // Clear custom selection
            selectedTab = .defaults
          }
        )
      }
    }
  }

  private var customPresetsList: some View {
    VStack(spacing: 8) {
      if presetManager.presets.isEmpty {
        // Enhanced empty state
        VStack(spacing: 12) {
          Image(systemName: "star.slash")
            .font(.system(size: 32))
            .foregroundStyle(.secondary.opacity(0.5))

          Text("No custom presets yet")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)

          Text("Save your current settings to create your first preset")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
      } else {
        ForEach(presetManager.presets) { preset in
          PresetCard(
            title: preset.name,
            subtitle: presetSubtitle(for: preset),
            icon: preset.icon,
            iconColor: .accentColor,
            rightContent: .badge(preset.format.displayName.uppercased()),
            isSelected: isCustomPresetSelected(preset),
            action: {
              selectCustomPreset(preset)
            }
          )
        }
      }
    }
  }

  private func presetSubtitle(for preset: Preset) -> String {
    var parts: [String] = []

    // Quality (only for formats that support it)
    if preset.format.supportsQuality {
      parts.append("\(Int(preset.qualityPercent))% quality")
    }

    // Size (only if not 100%)
    if preset.resizePercent != 100 {
      parts.append("\(Int(preset.resizePercent))% size")
    }

    // Description
    parts.append(preset.description)

    return parts.joined(separator: " • ")
  }

  private func isDefaultPresetSelected(_ preset: Preset) -> Bool {
    // Only selected if this is the selected preset AND no custom preset is active
    appState.selectedPreset == preset && selectedCustomPresetId == nil
  }

  private func isCustomPresetSelected(_ preset: Preset) -> Bool {
    // Check if this specific preset is selected by ID
    preset.id == selectedCustomPresetId
  }

  private func selectCustomPreset(_ preset: Preset) {
    // Apply the preset's form and track which preset was selected
    appState.conversionForm = preset.makeForm()
    selectedCustomPresetId = preset.id
    selectedTab = .custom
  }
}

// MARK: - Unified Preset Card

private struct PresetCard: View {
  let title: String
  let subtitle: String
  let icon: String
  let iconColor: Color
  let rightContent: RightContent
  let isSelected: Bool
  let action: () -> Void

  enum RightContent {
    case badge(String)
    case checkmark
    case none
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        // Icon with background
        ZStack {
          Circle()
            .fill(iconColor.opacity(isSelected ? 0.2 : 0.1))
            .frame(width: 40, height: 40)

          Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(isSelected ? iconColor : Color.secondary)
        }

        // Text content
        VStack(alignment: .leading, spacing: 3) {
          Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)

          Text(subtitle)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Right content
        rightContentView
      }
      .padding(12)
      .contentShape(Rectangle())
      .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .strokeBorder(
            isSelected ? Color.accentColor.opacity(0.3) : Color.clear,
            lineWidth: 1.5
          )
      )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var rightContentView: some View {
    switch rightContent {
    case .badge(let text):
      Text(text)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          Capsule().fill(
            isSelected
              ? Color.accentColor.opacity(0.15)
              : Color.secondary.opacity(0.1)
          )
        )
    case .checkmark:
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 18))
        .foregroundStyle(Color.accentColor)
    case .none:
      EmptyView()
    }
  }
}
