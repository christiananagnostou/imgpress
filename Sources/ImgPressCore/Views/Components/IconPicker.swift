import SwiftUI

/// Curated collection of SF Symbols suitable for preset icons
struct IconPicker: View {
  @Binding var selectedIcon: String
  @State private var isExpanded = false

  // Curated SF Symbols organized by category
  private static let icons: [(category: String, symbols: [String])] = [
    (
      "Stars & Favorites",
      [
        "star.fill", "star.circle.fill", "star.square.fill", "sparkles", "sparkle",
        "heart.fill", "heart.circle.fill", "bolt.heart.fill",
      ]
    ),
    (
      "Shapes & Symbols",
      [
        "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "hexagon.fill",
        "pentagon.fill", "seal.fill", "app.fill", "square.grid.2x2.fill",
      ]
    ),
    (
      "Nature & Weather",
      [
        "leaf.fill", "leaf.circle.fill", "flame.fill", "drop.fill", "snowflake",
        "sun.max.fill", "moon.fill", "cloud.fill", "bolt.fill", "wind",
      ]
    ),
    (
      "Photography",
      [
        "camera.fill", "photo.fill", "photo.stack.fill", "camera.aperture",
        "camera.filters", "wand.and.stars", "sparkles.rectangle.stack.fill",
        "square.and.arrow.up.fill", "photo.badge.plus.fill",
      ]
    ),
    (
      "Media & Audio",
      [
        "music.note", "play.fill", "pause.fill", "playpause.fill",
        "forward.fill", "backward.fill", "speaker.wave.3.fill", "headphones",
      ]
    ),
    (
      "Communication",
      [
        "envelope.fill", "paperplane.fill", "phone.fill", "message.fill",
        "bubble.left.fill", "quote.bubble.fill", "bell.fill",
      ]
    ),
    (
      "Travel & Places",
      [
        "airplane", "car.fill", "bicycle", "figure.walk", "map.fill",
        "location.fill", "house.fill", "building.2.fill", "flag.fill",
      ]
    ),
    (
      "Objects",
      [
        "book.fill", "bookmark.fill", "tag.fill", "bag.fill", "cart.fill",
        "gift.fill", "crown.fill", "key.fill", "lightbulb.fill", "paintbrush.fill",
      ]
    ),
    (
      "Food & Drink",
      [
        "cup.and.saucer.fill", "mug.fill", "wineglass.fill", "fork.knife",
        "birthday.cake.fill", "carrot.fill", "leaf.fill",
      ]
    ),
    (
      "Sports & Fitness",
      [
        "figure.run", "figure.walk", "bicycle", "sportscourt.fill",
        "dumbbell.fill", "trophy.fill", "medal.fill", "soccerball",
      ]
    ),
    (
      "Technology",
      [
        "desktopcomputer", "laptopcomputer", "iphone", "ipad", "applewatch",
        "headphones", "keyboard.fill", "printer.fill", "externaldrive.fill",
      ]
    ),
    (
      "Arrows & Directions",
      [
        "arrow.up.circle.fill", "arrow.down.circle.fill", "arrow.right.circle.fill",
        "arrow.clockwise.circle.fill", "arrow.triangle.2.circlepath",
        "arrow.up.arrow.down.circle.fill",
      ]
    ),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Icon")
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)

      DisclosureGroup(isExpanded: $isExpanded) {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            ForEach(Self.icons, id: \.category) { group in
              VStack(alignment: .leading, spacing: 8) {
                Text(group.category)
                  .font(.caption2.weight(.semibold))
                  .foregroundStyle(.tertiary)
                  .textCase(.uppercase)

                LazyVGrid(
                  columns: [
                    GridItem(.adaptive(minimum: 40), spacing: 8)
                  ],
                  spacing: 8
                ) {
                  ForEach(group.symbols, id: \.self) { symbol in
                    IconButton(
                      symbol: symbol,
                      isSelected: selectedIcon == symbol
                    ) {
                      selectedIcon = symbol
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = false
                      }
                    }
                  }
                }
              }
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
        }
        .frame(maxHeight: 300)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.secondary.opacity(0.04))
        )
      } label: {
        HStack {
          // Selected icon preview
          Image(systemName: selectedIcon)
            .font(.system(size: 20))
            .foregroundStyle(Color.accentColor)
            .frame(width: 40, height: 40)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(Circle())

          Text("Tap to choose an icon")
            .font(.caption)
            .foregroundStyle(.secondary)

          Spacer()
        }
        .contentShape(Rectangle())
      }
      .disclosureGroupStyle(IconPickerDisclosureStyle())
    }
  }
}

// MARK: - Icon Button

private struct IconButton: View {
  let symbol: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 18))
        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        .frame(width: 40, height: 40)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
              isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.secondary.opacity(0.05)
            )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(
              isSelected ? Color.accentColor.opacity(0.5) : Color.clear,
              lineWidth: 1.5
            )
        )
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Custom Disclosure Style

private struct IconPickerDisclosureStyle: DisclosureGroupStyle {
  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: 8) {
      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          configuration.isExpanded.toggle()
        }
      } label: {
        HStack {
          configuration.label
          Image(systemName: "chevron.down")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(configuration.isExpanded ? 180 : 0))
        }
        .padding(8)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.secondary.opacity(0.04))
        )
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      if configuration.isExpanded {
        configuration.content
      }
    }
  }
}
