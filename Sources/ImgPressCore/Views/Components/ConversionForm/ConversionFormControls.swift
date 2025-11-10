import SwiftUI

struct ConversionFormControls: View {
  @Binding var form: ConversionForm
  @State private var advancedExpanded = false
  var onBrowseDirectory: (() -> Void)? = nil

  var body: some View {
    VStack(spacing: 16) {
      ConversionSettingsSection(form: $form)
      AdvancedOptionsSection(
        form: $form,
        isExpanded: $advancedExpanded,
        onBrowseDirectory: onBrowseDirectory
      )
    }
  }
}
