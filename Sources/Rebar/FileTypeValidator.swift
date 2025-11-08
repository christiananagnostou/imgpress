import Foundation
import UniformTypeIdentifiers

/// Centralized file type validation for consistent behavior across the app
enum FileTypeValidator {
    /// Supported image and media types for Rebar
    static let supportedTypes: [UTType] = [
        .image,
        .rawImage,
        .livePhoto,
        UTType("com.canon.cr2-raw-image"),
        UTType("public.heic"),
        UTType("com.canon.cr3-raw-image"),
        UTType("com.adobe.raw-image"),
        UTType("com.apple.protected-mpeg-4-audio"),
        UTType("com.apple.quicktime-image")
    ].compactMap { $0 }
    
    /// Check if a URL points to an acceptable image/media file
    static func isAcceptable(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
              let type = UTType(typeIdentifier) else {
            return false
        }
        return supportedTypes.contains(where: { type.conforms(to: $0) })
    }
}
