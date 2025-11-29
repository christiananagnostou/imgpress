import SwiftUI

/// Displays before/after file size comparison for conversion results
struct SizeComparisonView: View {
  let originalSize: Int64
  let outputSize: Int64
  let isSmaller: Bool

  var body: some View {
    HStack(spacing: 20) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Original")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text(Formatters.byteCount.string(fromByteCount: originalSize))
          .font(.subheadline.weight(.semibold))
          .monospacedDigit()
      }

      Image(systemName: "arrow.right")
        .font(.caption)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 4) {
        Text("Optimized")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text(Formatters.byteCount.string(fromByteCount: outputSize))
          .font(.subheadline.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(isSmaller ? .green : .orange)
      }

      Spacer()
    }
  }
}
