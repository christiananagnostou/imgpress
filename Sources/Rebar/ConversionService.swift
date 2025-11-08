import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ConversionServiceError: LocalizedError, Sendable {
    case unsupportedFormat
    case imageReadFailed
    case destinationCreationFailed
    case conversionFailed
    case directoryCreationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "This format is not supported on your Mac."
        case .imageReadFailed:
            return "Couldn't read the original image."
        case .destinationCreationFailed:
            return "Failed to create the destination file."
        case .conversionFailed:
            return "Image conversion failed."
        case .directoryCreationFailed(let path):
            return "Couldn't create output directory at \(path)."
        }
    }
}

struct ConversionResult: Sendable, Equatable {
    let originalSize: Int64
    let outputSize: Int64
    let outputURL: URL
    let duration: TimeInterval

    var percentChange: Double {
        guard originalSize > 0 else { return 0 }
        let delta = Double(outputSize - originalSize)
        return delta / Double(originalSize) * 100
    }

    var sizeDelta: Int64 {
        outputSize - originalSize
    }

    var isSmaller: Bool {
        outputSize <= originalSize
    }
}

final class ConversionService {
    func convert(
        item: DroppedItem,
        form: ConversionForm,
        progress: ((ConversionStage) -> Void)? = nil
    ) async throws -> ConversionResult {
        try await Task.detached(priority: .userInitiated) {
            try self.performConversion(item: item, form: form, progress: progress)
        }.value
    }

    private func performConversion(
        item: DroppedItem,
        form: ConversionForm,
        progress: ((ConversionStage) -> Void)?
    ) throws -> ConversionResult {
        let startTime = Date()

        let fm = FileManager.default
        let originalAttributes = try fm.attributesOfItem(atPath: item.url.path)
        let originalSize = (originalAttributes[.size] as? NSNumber)?.int64Value ?? 0

        let outputDirectoryPath = (form.outputDirectoryPath as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        progress?(.ensuringOutputDirectory)
        if !fm.fileExists(atPath: outputDirectoryPath, isDirectory: &isDir) {
            do {
                try fm.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)
            } catch {
                throw ConversionServiceError.directoryCreationFailed(outputDirectoryPath)
            }
        }

        let baseName = item.url.deletingPathExtension().lastPathComponent
        let finalName = baseName + form.filenameSuffix
        let outputURL = URL(fileURLWithPath: outputDirectoryPath)
            .appendingPathComponent(finalName)
            .appendingPathExtension(form.format.fileExtension)

        guard let destUTType = form.format.cgImageUTType else {
            throw ConversionServiceError.unsupportedFormat
        }

        progress?(.loadingInput)
        guard let imageSource = CGImageSourceCreateWithURL(item.url as CFURL, nil) else {
            throw ConversionServiceError.imageReadFailed
        }

        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, destUTType as CFString, 1, nil) else {
            throw ConversionServiceError.destinationCreationFailed
        }

        var options: [CFString: Any] = [:]

        if let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) {
            if form.preserveMetadata {
                options[kCGImageDestinationMetadata] = metadata
            }
        }

        if form.format.supportsQuality {
            options[kCGImageDestinationLossyCompressionQuality] = form.quality / 100.0
        }

        if form.resizeEnabled,
           let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
           let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
           let height = properties[kCGImagePropertyPixelHeight] as? CGFloat {
            progress?(.resizing)
            let scale = CGFloat(form.resizePercent / 100.0)
            let maxDimension = Int(max(width, height) * scale)
            options[kCGImageDestinationImageMaxPixelSize] = max(1, maxDimension)
        }

        progress?(.writingOutput)
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionServiceError.conversionFailed
        }

        let outputAttributes = try fm.attributesOfItem(atPath: outputURL.path)
        let outputSize = (outputAttributes[.size] as? NSNumber)?.int64Value ?? 0

        let duration = Date().timeIntervalSince(startTime)
        progress?(.finished)
        return ConversionResult(
            originalSize: originalSize,
            outputSize: outputSize,
            outputURL: outputURL,
            duration: duration
        )
    }
}

enum ConversionStage: String, Sendable {
    case ensuringOutputDirectory = "Creating output directory"
    case loadingInput = "Loading image"
    case resizing = "Resizing"
    case writingOutput = "Encoding"
    case finished = "Completed"
}

extension ConversionStage {
    var shortLabel: String {
        switch self {
        case .ensuringOutputDirectory:
            return "Dir"
        case .loadingInput:
            return "Load"
        case .resizing:
            return "Size"
        case .writingOutput:
            return "Encode"
        case .finished:
            return "Done"
        }
    }
}

private extension ImageFormat {
    var cgImageUTType: String? {
        switch self {
        case .jpeg:
            return UTType.jpeg.identifier
        case .png:
            return UTType.png.identifier
        case .webp:
            if #available(macOS 14, *) {
                return UTType.webP.identifier
            } else {
                return nil
            }
        case .avif:
            if #available(macOS 15, *) {
                return "public.avif"
            } else {
                return nil
            }
        }
    }
}
