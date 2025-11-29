import SwiftUI

/// Displays a single tip with icon and text (used in empty state)
struct TipRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.caption)
        .foregroundStyle(Color.accentColor)
        .frame(width: 20)

      Text(text)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}
