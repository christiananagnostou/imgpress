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
struct FormTextField: View {
  let label: String
  let placeholder: String
  @Binding var text: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
      TextField(placeholder, text: $text)
        .textFieldStyle(.roundedBorder)
        .font(.caption)
    }
  }
}

/// Icon picker field with preview
struct FormIconPicker: View {
  let label: String
  @Binding var iconName: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
      HStack {
        TextField("SF Symbol name", text: $iconName)
          .textFieldStyle(.roundedBorder)
          .font(.caption)

        // Icon preview
        Image(systemName: iconName)
          .font(.system(size: 20))
          .foregroundStyle(Color.accentColor)
          .frame(width: 40, height: 40)
          .background(Color.accentColor.opacity(0.1))
          .clipShape(Circle())
      }
    }
  }
}
