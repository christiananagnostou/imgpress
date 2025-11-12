import SwiftUI

/// Custom disclosure group style that makes the entire label area clickable
struct FullWidthDisclosureStyle: DisclosureGroupStyle {
  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: 0) {
      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          configuration.isExpanded.toggle()
        }
      } label: {
        HStack {
          configuration.label
          Spacer()
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .padding(.bottom, configuration.isExpanded ? 12 : 0)

      if configuration.isExpanded {
        configuration.content
      }
    }
  }
}
