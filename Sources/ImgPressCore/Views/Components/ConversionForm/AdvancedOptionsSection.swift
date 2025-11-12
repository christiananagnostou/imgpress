import SwiftUI

struct AdvancedOptionsSection: View {
  @Binding var form: ConversionForm
  @Binding var isExpanded: Bool
  var onBrowseDirectory: (() -> Void)? = nil

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading, spacing: 12) {
        // Output Directory
        FormTextField(
          label: "Output Directory",
          placeholder: "Path",
          text: $form.outputDirectoryPath
        ) {
          Button {
            onBrowseDirectory?()
          } label: {
            Image(systemName: "folder")
              .font(.subheadline)
          }
          .buttonStyle(.plain)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color.secondary.opacity(0.08))
          )
          .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
          )
        }

        // Filename Suffix
        FormTextField(
          label: "Filename Suffix",
          placeholder: "_imgpress",
          text: $form.filenameSuffix
        )
      }
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
