import Foundation

enum ImageFormat: String, CaseIterable, Identifiable, Sendable {
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

struct ConversionForm: Sendable {
    var format: ImageFormat
    var quality: Double
    var preserveMetadata: Bool
    var resizeEnabled: Bool
    var resizePercent: Double
    var outputDirectoryPath: String
    var filenameSuffix: String

    static func makeDefault(format: ImageFormat = .jpeg) -> ConversionForm {
        ConversionForm(
            format: format,
            quality: 75,
            preserveMetadata: true,
            resizeEnabled: false,
            resizePercent: 100,
            outputDirectoryPath: "~/Desktop/ImgPress",
            filenameSuffix: ""
        )
    }
}

struct ConversionPreset: Identifiable, Equatable, Sendable {
    let id = UUID()
    let name: String
    let detail: String
    let hero: String
    let defaultFormat: ImageFormat
    let defaultQuality: Double
    let defaultResizePercent: Double
    let preserveMetadata: Bool

    func makeForm() -> ConversionForm {
        ConversionForm(
            format: defaultFormat,
            quality: defaultQuality,
            preserveMetadata: preserveMetadata,
            resizeEnabled: defaultResizePercent != 100,
            resizePercent: defaultResizePercent,
            outputDirectoryPath: "~/Desktop/ImgPress",
            filenameSuffix: ""
        )
    }

    static let defaults: [ConversionPreset] = [
        ConversionPreset(
            name: "Shareable JPEG",
            detail: "75% quality • metadata preserved",
            hero: "sparkles",
            defaultFormat: .jpeg,
            defaultQuality: 75,
            defaultResizePercent: 100,
            preserveMetadata: true
        ),
        ConversionPreset(
            name: "Transparent PNG",
            detail: "Lossless • best for logos",
            hero: "rectangle.and.arrow.up.right.and.arrow.down.left",
            defaultFormat: .png,
            defaultQuality: 100,
            defaultResizePercent: 100,
            preserveMetadata: true
        ),
        ConversionPreset(
            name: "High-efficiency AVIF",
            detail: "45% smaller • modern devices",
            hero: "leaf",
            defaultFormat: .avif,
            defaultQuality: 60,
            defaultResizePercent: 100,
            preserveMetadata: true
        ),
    ]
}
