import SwiftUI

/// Reusable slider control with label, icon, and percentage display
struct SliderControl: View {
  let title: String
  let icon: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double
  let tintColor: Color
  let valueColor: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label(title, systemImage: icon)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(Int(value))%")
          .font(.subheadline.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(valueColor)
      }

      Slider(value: $value, in: range, step: step)
        .tint(tintColor)
    }
  }
}
