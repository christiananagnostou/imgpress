import SwiftUI

/// Reusable component for grouping related form fields with consistent styling
struct FormFieldSection<Content: View>: View {
  let title: String?
  let icon: String?
  let content: Content

  init(
    title: String? = nil,
    icon: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.icon = icon
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: title != nil ? 12 : 0) {
      if let title = title {
        if let icon = icon {
          Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
        } else {
          Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
        }
      }

      content
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.secondary.opacity(0.04))
    )
  }
}

/// Simple labeled text field for forms
struct FormTextField<TrailingContent: View>: View {
  let label: String
  let placeholder: String
  @Binding var text: String
  let trailingContent: (() -> TrailingContent)?

  init(
    label: String,
    placeholder: String,
    text: Binding<String>,
    @ViewBuilder trailingContent: @escaping () -> TrailingContent
  ) {
    self.label = label
    self.placeholder = placeholder
    self._text = text
    self.trailingContent = trailingContent
  }

  init(
    label: String,
    placeholder: String,
    text: Binding<String>
  ) where TrailingContent == EmptyView {
    self.label = label
    self.placeholder = placeholder
    self._text = text
    self.trailingContent = nil
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)

      if let trailing = trailingContent {
        HStack(spacing: 8) {
          StyledTextField(placeholder: placeholder, text: $text)
          trailing()
        }
      } else {
        StyledTextField(placeholder: placeholder, text: $text)
      }
    }
  }
}

/// Styled text field matching app design
private struct StyledTextField: View {
  let placeholder: String
  @Binding var text: String

  var body: some View {
    TextField(placeholder, text: $text)
      .textFieldStyle(.plain)
      .font(.subheadline)
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
}

/// Icon picker field with preview
struct FormIconPicker: View {
  let label: String
  @Binding var iconName: String

  var body: some View {
    IconPicker(selectedIcon: $iconName)
  }
}
