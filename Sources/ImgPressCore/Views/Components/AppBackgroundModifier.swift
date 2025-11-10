import SwiftUI

/// ViewModifier that applies the standard app background gradient
/// Used across main views
struct AppBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    ZStack {
      // Background gradient
      LinearGradient(
        colors: [
          Color(nsColor: .controlBackgroundColor),
          Color(nsColor: .windowBackgroundColor),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      content
    }
  }
}

extension View {
  /// Apply the standard app background gradient
  func appBackground() -> some View {
    modifier(AppBackgroundModifier())
  }
}
