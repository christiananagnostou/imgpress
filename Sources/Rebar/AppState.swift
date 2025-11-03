import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    @Published var latestDrop: DroppedItem?
    @Published var dropError: DropError?

    func register(drop urls: [URL]) {
        guard let firstSupported = urls.lazy.compactMap(firstAcceptableFile).first else {
            dropError = .noUsableFiles
            return
        }

        latestDrop = DroppedItem(url: firstSupported)
        dropError = nil
    }

    private func firstAcceptableFile(_ url: URL) -> URL? {
        guard url.isFileURL else { return nil }
        if let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let type = UTType(typeIdentifier) {
            let allowedTypes: [UTType] = [
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

            guard allowedTypes.contains(where: { type.conforms(to: $0) }) else {
                return nil
            }
        }
        return url
    }
}

struct DroppedItem: Identifiable {
    let id = UUID()
    let url: URL
    let displayName: String
    let uniformTypeDescription: String?
    let uniformTypeIdentifier: String?

    init(url: URL) {
        self.url = url
        displayName = url.lastPathComponent

        if let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
            let utType = UTType(typeIdentifier)
            uniformTypeDescription = utType?.localizedDescription ?? typeIdentifier
            uniformTypeIdentifier = typeIdentifier
        } else {
            uniformTypeDescription = nil
            uniformTypeIdentifier = nil
        }
    }
}

enum DropError: LocalizedError {
    case noUsableFiles
    case securityScopedResourceDenied
    case fileAccessFailed(URL)

    var errorDescription: String? {
        switch self {
        case .noUsableFiles:
            return "Drag a supported image file to get started."
        case .securityScopedResourceDenied:
            return "macOS denied access to the dropped file."
        case .fileAccessFailed(let url):
            return "Could not access \(url.lastPathComponent)."
        }
    }
}
