import SwiftUI

struct GeneralSettingsTab: View {
  @ObservedObject var manager: PresetManager

  var body: some View {
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
          .frame(maxWidth: .infinity, alignment: .leading)
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
}
