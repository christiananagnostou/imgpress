import Foundation

/// Shared JSON encoder and decoder to avoid repeated allocations
enum Coders {
    static let jsonEncoder = JSONEncoder()
    static let jsonDecoder = JSONDecoder()
}
