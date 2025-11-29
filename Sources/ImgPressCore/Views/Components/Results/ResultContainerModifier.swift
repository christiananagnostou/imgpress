import SwiftUI

/// ViewModifier that applies result-specific styling based on conversion outcome
struct ResultContainerModifier: ViewModifier {
  let isSmaller: Bool

  func body(content: Content) -> some View {
    content
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(isSmaller ? Color.green.opacity(0.08) : Color.orange.opacity(0.08))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .strokeBorder(
            isSmaller ? Color.green.opacity(0.3) : Color.orange.opacity(0.3),
            lineWidth: 1)
      )
      .transition(.opacity.combined(with: .move(edge: .bottom)))
  }
}

extension View {
  /// Apply result container styling with color based on conversion outcome
  func resultContainer(isSmaller: Bool) -> some View {
    modifier(ResultContainerModifier(isSmaller: isSmaller))
  }
}
