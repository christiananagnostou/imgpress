import Foundation

/// Shared formatters to prevent recreation and ensure consistency
enum Formatters {
  /// Shared byte count formatter for file sizes
  /// Used across result views to display file sizes consistently
  /// Thread-safe: formatter is immutable after initialization
  nonisolated(unsafe) static let byteCount: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter
  }()
}
