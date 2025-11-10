import SwiftUI

/// Displays percentage change and size delta for conversion results
struct PercentChangeBadge: View {
  let percentChange: Double
  let sizeDelta: Int64
  let isSmaller: Bool

  var body: some View {
    VStack(alignment: .trailing, spacing: 4) {
      // Display percentage change with sign
      let percent = abs(percentChange)
      let formatted = String(format: "%.1f%%", percent)
      Text(isSmaller ? "-\(formatted)" : "+\(formatted)")
        .font(.title3.weight(.bold))
        .monospacedDigit()
        .foregroundStyle(isSmaller ? .green : .orange)

      // Display absolute size difference
      let savedBytes = abs(sizeDelta)
      Text(
        isSmaller
          ? "saved \(Formatters.byteCount.string(fromByteCount: savedBytes))"
          : "added \(Formatters.byteCount.string(fromByteCount: savedBytes))"
      )
      .font(.caption2)
      .foregroundStyle(.secondary)
    }
  }
}
