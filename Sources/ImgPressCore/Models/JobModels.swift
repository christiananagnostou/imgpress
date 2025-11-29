import AppKit
import Foundation
import UniformTypeIdentifiers

// MARK: - Dropped Item

/// Represents a file dropped into the application for processing
struct DroppedItem: Identifiable, Sendable {
  let id = UUID()
  let url: URL
  let displayName: String
  let uniformTypeDescription: String?
  let uniformTypeIdentifier: String?

  init(url: URL) {
    self.url = url
    displayName = url.lastPathComponent

    if let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey])
      .typeIdentifier
    {
      let utType = UTType(typeIdentifier)
      uniformTypeDescription = utType?.localizedDescription ?? typeIdentifier
      uniformTypeIdentifier = typeIdentifier
    } else {
      uniformTypeDescription = nil
      uniformTypeIdentifier = nil
    }
  }

  func thumbnail(maxDimension: CGFloat = 40) -> NSImage? {
    ThumbnailCache.shared.thumbnail(for: url, maxDimension: maxDimension)
  }
}

// MARK: - Thumbnail Cache

/// Thread-safe thumbnail cache with size-based eviction
/// Note: Eviction is not true LRU (least-recently-used) but removes arbitrary entries when full
final class ThumbnailCache: Sendable {
  static let shared = ThumbnailCache()
  private let cache: Cache = Cache()
  private let maxCacheSize = 100

  private init() {}

  private final class Cache: @unchecked Sendable {
    private var storage: [URL: NSImage] = [:]
    private let lock = NSLock()

    func get(_ url: URL) -> NSImage? {
      lock.lock()
      defer { lock.unlock() }
      return storage[url]
    }

    func set(_ url: URL, image: NSImage) {
      lock.lock()
      defer { lock.unlock() }
      storage[url] = image
    }

    func removeFirst() {
      lock.lock()
      defer { lock.unlock() }
      if let firstKey = storage.keys.first {
        storage.removeValue(forKey: firstKey)
      }
    }

    func removeAll() {
      lock.lock()
      defer { lock.unlock() }
      storage.removeAll()
    }

    var count: Int {
      lock.lock()
      defer { lock.unlock() }
      return storage.count
    }
  }

  func thumbnail(for url: URL, maxDimension: CGFloat) -> NSImage? {
    if let cached = cache.get(url) {
      return cached
    }

    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
      let cgImage = CGImageSourceCreateThumbnailAtIndex(
        imageSource, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maxDimension,
        ] as CFDictionary)
    else {
      return nil
    }

    let size = NSSize(width: cgImage.width, height: cgImage.height)
    let thumbnail = NSImage(cgImage: cgImage, size: size)

    if cache.count >= maxCacheSize {
      cache.removeFirst()
    }
    cache.set(url, image: thumbnail)

    return thumbnail
  }

  func clearCache() {
    cache.removeAll()
  }
}

// MARK: - Drop Error

enum DropError: LocalizedError, Sendable {
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

// MARK: - Conversion Job

/// Status of an individual conversion job
enum ConversionJobStatus: Equatable, Sendable {
  case pending
  case inProgress(step: ConversionStage)
  case completed(ConversionResult)
  case failed(String)
}

/// Represents an individual file conversion job
struct ConversionJob: Identifiable, Sendable {
  let id = UUID()
  let item: DroppedItem
  var status: ConversionJobStatus = .pending
}

// MARK: - Conversion Summary

/// Aggregate statistics for a batch conversion operation
struct ConversionSummary: Equatable, Sendable {
  let totalFiles: Int
  let completedCount: Int
  let failedCount: Int
  let totalOriginalSize: Int64
  let totalOutputSize: Int64
  let duration: TimeInterval

  var totalSizeDelta: Int64 {
    totalOutputSize - totalOriginalSize
  }

  var percentChange: Double {
    guard totalOriginalSize > 0 else { return 0 }
    let delta = Double(totalSizeDelta)
    let original = Double(totalOriginalSize)
    return (delta / original) * 100
  }

  var isSmaller: Bool {
    totalOutputSize < totalOriginalSize
  }

  var averageTimePerFile: TimeInterval {
    guard completedCount > 0 else { return 0 }
    return duration / TimeInterval(completedCount)
  }
}
