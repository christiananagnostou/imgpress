import SwiftUI

struct ConversionSettingsSection: View {
  @Binding var form: ConversionForm

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Format picker
      VStack(alignment: .leading, spacing: 10) {
        Label("Output Format", systemImage: "doc.badge.gearshape")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)

        ModernSegmentedControl(
          selection: $form.format,
          options: ImageFormat.allCases,
          titleProvider: { $0.displayName },
          iconProvider: nil
        )
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Quality slider
      if form.format.supportsQuality {
        SliderControl(
          title: "Quality",
          icon: "dial.medium",
          value: $form.quality,
          range: 30...100,
          step: 1,
          tintColor: .accentColor,
          valueColor: .primary
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
      }

      // Resize scale slider
      SliderControl(
        title: "Resize Scale",
        icon: "arrow.up.left.and.down.right.magnifyingglass",
        value: $form.resizePercent,
        range: 20...150,
        step: 5,
        tintColor: .orange,
        valueColor: .orange
      )

      Divider()
        .padding(.vertical, 2)

      // Preserve metadata toggle
      Toggle(isOn: $form.preserveMetadata) {
        HStack(spacing: 8) {
          Image(systemName: "tag.fill")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(width: 20)
          Text("Preserve Metadata")
            .font(.subheadline)
        }
      }
      .toggleStyle(.switch)
    }
    .animation(.spring(response: 0.3), value: form.format.supportsQuality)
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.secondary.opacity(0.04))
    )
  }
}
