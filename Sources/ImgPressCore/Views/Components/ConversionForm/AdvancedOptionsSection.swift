import SwiftUI

struct AdvancedOptionsSection: View {
  @Binding var form: ConversionForm
  @Binding var isExpanded: Bool
  var onBrowseDirectory: (() -> Void)? = nil

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading, spacing: 12) {
        // Output Directory
        VStack(alignment: .leading, spacing: 8) {
          Text("Output Directory")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
          HStack(spacing: 8) {
            TextField("Path", text: $form.outputDirectoryPath)
              .textFieldStyle(.roundedBorder)
              .font(.caption)

            Button {
              onBrowseDirectory?()
            } label: {
              Image(systemName: "folder")
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
          }
        }

        // Filename Suffix
        VStack(alignment: .leading, spacing: 8) {
          Text("Filename Suffix")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
          TextField("_imgpress", text: $form.filenameSuffix)
            .textFieldStyle(.roundedBorder)
            .font(.caption)
        }
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 12)
    } label: {
      Label("Advanced Options", systemImage: "gearshape.2")
        .font(.subheadline.weight(.medium))
    }
    .disclosureGroupStyle(FullWidthDisclosureStyle())
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.secondary.opacity(0.04))
    )
  }
}
