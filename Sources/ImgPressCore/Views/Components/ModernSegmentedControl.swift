import SwiftUI

/// Modern segmented control with sliding animation and customizable options
struct ModernSegmentedControl<T: Hashable>: View {
  @Binding var selection: T
  let options: [T]
  let titleProvider: (T) -> String
  let iconProvider: ((T) -> String?)?
  @Namespace private var animation

  var body: some View {
    HStack(spacing: 0) {
      ForEach(options, id: \.self) { option in
        segmentButton(for: option)
      }
    }
    .padding(4)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.secondary.opacity(0.1))
    )
  }

  private func segmentButton(for option: T) -> some View {
    let title = titleProvider(option)
    let icon = iconProvider?(option)
    let isSelected = selection == option

    return Button {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        selection = option
      }
    } label: {
      HStack(spacing: 6) {
        if let icon = icon {
          Image(systemName: icon)
            .font(.caption2)
        }
        Text(title)
          .font(.caption.weight(.medium))
      }
      .foregroundStyle(isSelected ? Color.primary : Color.secondary)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            .matchedGeometryEffect(id: "segment_background", in: animation)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Convenience Initializers

extension ModernSegmentedControl {
  /// Create a segmented control with explicit title and icon for each option
  init(
    selection: Binding<T>,
    options: [(value: T, title: String, icon: String?)]
  ) {
    self._selection = selection
    self.options = options.map(\.value)

    // Create lookup dictionaries for O(1) access
    let titleLookup = Dictionary(uniqueKeysWithValues: options.map { ($0.value, $0.title) })
    let iconLookup = Dictionary(
      uniqueKeysWithValues: options.compactMap { option in
        option.icon.map { (option.value, $0) }
      })

    self.titleProvider = { titleLookup[$0] ?? "" }
    self.iconProvider = { iconLookup[$0] }
  }
}
