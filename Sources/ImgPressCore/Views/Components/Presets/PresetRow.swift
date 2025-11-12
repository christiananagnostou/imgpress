import SwiftUI

struct PresetRow: View {
  let preset: Preset
  let showIcon: Bool
  let showEditButton: Bool
  let showDeleteButton: Bool
  let isSelected: Bool
  let showBadge: Bool
  let onEdit: (() -> Void)?
  let onDelete: (() -> Void)?
  let onTap: (() -> Void)?

  init(
    preset: Preset,
    showIcon: Bool = false,
    showEditButton: Bool = true,
    showDeleteButton: Bool = false,
    isSelected: Bool = false,
    showBadge: Bool = false,
    onEdit: (() -> Void)? = nil,
    onDelete: (() -> Void)? = nil,
    onTap: (() -> Void)? = nil
  ) {
    self.preset = preset
    self.showIcon = showIcon
    self.showEditButton = showEditButton
    self.showDeleteButton = showDeleteButton
    self.isSelected = isSelected
    self.showBadge = showBadge
    self.onEdit = onEdit
    self.onDelete = onDelete
    self.onTap = onTap
  }

  var body: some View {
    Group {
      if let onTap = onTap {
        Button(action: onTap) {
          rowContent
        }
        .buttonStyle(.plain)
      } else {
        rowContent
      }
    }
  }

  private var rowContent: some View {
    HStack(spacing: showIcon ? 12 : 0) {
      // Optional icon
      if showIcon {
        ZStack {
          Circle()
            .fill(Color.accentColor.opacity(isSelected ? 0.2 : 0.1))
            .frame(width: 40, height: 40)

          Image(systemName: preset.icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
      }

      // Preset info
      VStack(alignment: .leading, spacing: 4) {
        Text(preset.name)
          .font(showIcon ? .subheadline.weight(.medium) : .body)

        // Description on separate line
        if !preset.description.isEmpty {
          Text(preset.description)
            .font(.caption)
            .foregroundStyle(.tertiary)
        }

        // Format and settings details
        HStack(spacing: 8) {
          // Only show format label if badge is not displayed (avoid redundancy)
          if !showBadge {
            Label(preset.format.displayName, systemImage: "photo")
          }

          if preset.format.supportsQuality {
            Text("\(Int(preset.qualityPercent))% quality")
          }

          if preset.resizePercent != 100 {
            Text("\(Int(preset.resizePercent))% scale")
          }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
      }

      Spacer()

      // Optional badge
      if showBadge {
        Text(preset.format.displayName.uppercased())
          .font(.caption2.weight(.semibold))
          .foregroundStyle(isSelected ? Color.accentColor : .secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            Capsule().fill(
              isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.secondary.opacity(0.1)
            )
          )
      }

      // Action buttons
      if showEditButton || showDeleteButton {
        HStack(spacing: 6) {
          // Edit button
          if showEditButton, let onEdit = onEdit {
            Button {
              onEdit()
            } label: {
              Image(systemName: "pencil")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                  Circle()
                    .fill(Color.secondary.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            .help("Edit preset")
          }

          // Delete button
          if showDeleteButton, let onDelete = onDelete {
            Button {
              onDelete()
            } label: {
              Image(systemName: "trash")
                .font(.system(size: 14))
                .foregroundStyle(.red)
                .frame(width: 28, height: 28)
                .background(
                  Circle()
                    .fill(Color.red.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            .help("Delete preset")
          }
        }
      }
    }
    .padding(showIcon ? 12 : 0)
    .padding(.vertical, showIcon ? 0 : 4)
    .contentShape(Rectangle())
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(isSelected && showIcon ? Color.accentColor.opacity(0.08) : Color.clear)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(
          isSelected && showIcon ? Color.accentColor.opacity(0.3) : Color.clear,
          lineWidth: 1.5
        )
    )
  }
}
