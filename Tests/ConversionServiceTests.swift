import Testing
import Foundation
@testable import ImgPressCore

@Suite("ConversionServiceError Tests")
struct ConversionServiceErrorTests {
    
    @Test("Error descriptions are user-friendly")
    func testErrorDescriptions() {
        #expect(ConversionServiceError.unsupportedFormat.errorDescription == "This format is not supported on your Mac.")
        #expect(ConversionServiceError.imageReadFailed.errorDescription == "Couldn't read the original image.")
        #expect(ConversionServiceError.conversionFailed.errorDescription == "Image conversion failed.")
    }
    
    @Test("Destination creation error includes format")
    func testDestinationCreationErrorIncludesFormat() {
        let error = ConversionServiceError.destinationCreationFailed("WebP")
        #expect(error.errorDescription?.contains("WebP") == true)
        #expect(error.errorDescription == "Failed to create destination for WebP format. This format may not be supported on your macOS version.")
    }
    
    @Test("Directory creation error includes path")
    func testDirectoryCreationErrorIncludesPath() {
        let error = ConversionServiceError.directoryCreationFailed("/tmp/output")
        #expect(error.errorDescription?.contains("/tmp/output") == true)
        #expect(error.errorDescription == "Couldn't create output directory at /tmp/output.")
    }
    
    @Test("Error is Sendable")
    func testErrorIsSendable() async {
        let error = ConversionServiceError.conversionFailed
        
        await Task.detached {
            _ = error.errorDescription
        }.value
    }
}

@Suite("ConversionService Tests")
struct ConversionServiceTests {
    
    @Test("ConversionService is Sendable")
    func testServiceIsSendable() async {
        let service = ConversionService()
        
        await Task.detached {
            // If ConversionService is properly Sendable, this compiles
            _ = service
        }.value
    }
    
    @Test("Service can be shared across tasks")
    func testServiceThreadSafety() async {
        let service = ConversionService()
        
        // Access service from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    _ = service
                }
            }
        }
        
        #expect(Bool(true))
    }
}
