import Foundation
import UniformTypeIdentifiers

/// Validates file types for image conversion support
enum FileTypeValidator {
    /// Supported image types including standard formats, RAW formats, and live photos
    static let supportedTypes: [UTType] = [
        .image,
        .rawImage,
        .livePhoto,
        UTType("com.canon.cr2-raw-image"),
        UTType("public.heic"),
        UTType("com.canon.cr3-raw-image"),
        UTType("com.adobe.raw-image"),
        UTType("com.apple.protected-mpeg-4-audio"),
        UTType("com.apple.quicktime-image"),
    ].compactMap { $0 }

    /// Checks if a file URL conforms to any supported image type
    static func isAcceptable(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        guard
            let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey])
                .typeIdentifier,
            let type = UTType(typeIdentifier)
        else {
            return false
        }
        return supportedTypes.contains(where: { type.conforms(to: $0) })
    }
}
