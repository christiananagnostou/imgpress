import Testing
import Foundation
import UniformTypeIdentifiers
@testable import ImgPressCore

@Suite("FileTypeValidator Tests")
struct FileTypeValidatorTests {
    
    @Test("Validator checks conformance to supported types")
    func testValidatorRequiresActualImageFiles() {
        // FileTypeValidator validates based on UTType conformance, not just extension
        // It checks if the file's type conforms to image types like .image, .rawImage, etc.
        // This test validates that the validator exists and has supported types defined
        #expect(FileTypeValidator.supportedTypes.count > 0)
        #expect(FileTypeValidator.supportedTypes.contains(.image))
    }
    
    @Test("Validator rejects non-file URLs")
    func testRejectsNonFileURLs() {
        let httpURL = URL(string: "https://example.com/image.jpg")!
        #expect(FileTypeValidator.isAcceptable(httpURL) == false)
    }
    
    @Test("Validator handles supported UTTypes")
    func testSupportedTypes() {
        let types = FileTypeValidator.supportedTypes
        
        // Should include common image types
        #expect(types.contains(.image))
        #expect(types.contains(.rawImage))
        #expect(types.contains(.livePhoto))
        
        // Should have multiple types configured
        #expect(types.count >= 3)
    }
}
