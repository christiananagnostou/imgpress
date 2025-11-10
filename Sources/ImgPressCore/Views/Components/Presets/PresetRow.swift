import SwiftUI

struct PresetRow: View {
  let preset: Preset
  let onEdit: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(preset.name)
          .font(.body)

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

      Button {
        onEdit()
      } label: {
        Image(systemName: "pencil")
          .font(.callout)
      }
      .buttonStyle(.plain)
      .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }
}
