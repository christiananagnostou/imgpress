import Foundation

// MARK: - Image Format

/// Supported output image formats
enum ImageFormat: String, CaseIterable, Identifiable, Sendable, Codable {
    case jpeg = "JPEG"
    case png = "PNG"
    case webp = "WebP"
    case avif = "AVIF"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var fileExtension: String {
        switch self {
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        case .webp:
            return "webp"
        case .avif:
            return "avif"
        }
    }

    var supportsQuality: Bool {
        switch self {
        case .png:
            return false
        case .jpeg, .webp, .avif:
            return true
        }
    }
}

// MARK: - Conversion Form

/// Configuration parameters for an image conversion operation
struct ConversionForm: Sendable, Codable, Equatable {
    var format: ImageFormat
    var quality: Double
    var preserveMetadata: Bool
    var resizePercent: Double
    var outputDirectoryPath: String
    var filenameSuffix: String

    static func makeDefault(format: ImageFormat = .jpeg) -> ConversionForm {
        ConversionForm(
            format: format,
            quality: 75,
            preserveMetadata: true,
            resizePercent: 100,
            outputDirectoryPath: "~/Desktop/ImgPress",
            filenameSuffix: ""
        )
    }
}

// MARK: - Preset

/// Unified preset structure for both default and custom presets
struct Preset: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var icon: String
    var format: ImageFormat
    var qualityPercent: Double
    var resizePercent: Double
    var preserveMetadata: Bool

    func makeForm() -> ConversionForm {
        ConversionForm(
            format: format,
            quality: qualityPercent,
            preserveMetadata: preserveMetadata,
            resizePercent: resizePercent,
            outputDirectoryPath: "~/Desktop/ImgPress",
            filenameSuffix: ""
        )
    }

    static let defaults: [Preset] = [
        Preset(
            name: "Shareable JPEG",
            description: "Best for websites",
            icon: "sparkles",
            format: .jpeg,
            qualityPercent: 75,
            resizePercent: 100,
            preserveMetadata: true
        ),
        Preset(
            name: "Transparent PNG",
            description: "Best for logos",
            icon: "rectangle.and.arrow.up.right.and.arrow.down.left",
            format: .png,
            qualityPercent: 100,
            resizePercent: 100,
            preserveMetadata: true
        ),
        Preset(
            name: "High-efficiency AVIF",
            description: "Modern devices",
            icon: "leaf",
            format: .avif,
            qualityPercent: 60,
            resizePercent: 100,
            preserveMetadata: true
        ),
    ]
}
