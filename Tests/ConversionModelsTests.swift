import Testing
import Foundation
@testable import ImgPressCore

@Suite("ImageFormat Tests")
struct ImageFormatTests {
    
    @Test("File extensions are correct")
    func testFileExtensions() {
        #expect(ImageFormat.jpeg.fileExtension == "jpg")
        #expect(ImageFormat.png.fileExtension == "png")
        #expect(ImageFormat.webp.fileExtension == "webp")
        #expect(ImageFormat.avif.fileExtension == "avif")
    }
    
    @Test("Quality support is correct")
    func testQualitySupport() {
        #expect(ImageFormat.jpeg.supportsQuality == true)
        #expect(ImageFormat.png.supportsQuality == false)
        #expect(ImageFormat.webp.supportsQuality == true)
        #expect(ImageFormat.avif.supportsQuality == true)
    }
    
    @Test("Display names match raw values")
    func testDisplayNames() {
        for format in ImageFormat.allCases {
            #expect(format.displayName == format.rawValue)
        }
    }
    
    @Test("All formats are identifiable")
    func testIdentifiable() {
        for format in ImageFormat.allCases {
            #expect(format.id == format.rawValue)
        }
    }
}

@Suite("ConversionForm Tests")
struct ConversionFormTests {
    
    @Test("Default form has correct values")
    func testDefaultForm() {
        let form = ConversionForm.makeDefault()
        
        #expect(form.format == .jpeg)
        #expect(form.quality == 75)
        #expect(form.preserveMetadata == true)
        #expect(form.resizeEnabled == false)
        #expect(form.resizePercent == 100)
        #expect(form.outputDirectoryPath == "~/Desktop/ImgPress")
        #expect(form.filenameSuffix == "_imgpress")
    }
    
    @Test("Can create form with custom format", arguments: ImageFormat.allCases)
    func testCustomFormatForm(format: ImageFormat) {
        let form = ConversionForm.makeDefault(format: format)
        #expect(form.format == format)
    }
    
    @Test("Form is Sendable")
    func testFormIsSendable() async {
        let form = ConversionForm.makeDefault()
        
        await Task.detached {
            // If ConversionForm is properly Sendable, this compiles
            _ = form.format
        }.value
    }
}

@Suite("ConversionPreset Tests")
struct ConversionPresetTests {
    
    @Test("Default presets exist")
    func testDefaultPresetsExist() {
        #expect(ConversionPreset.defaults.count > 0)
    }
    
    @Test("Preset forms have correct format")
    func testPresetFormFormat() {
        for preset in ConversionPreset.defaults {
            let form = preset.makeForm()
            #expect(form.format == preset.defaultFormat)
            #expect(form.quality == preset.defaultQuality)
            #expect(form.preserveMetadata == preset.preserveMetadata)
        }
    }
    
    @Test("Preset resize settings are applied")
    func testPresetResizeSettings() {
        let preset = ConversionPreset(
            name: "Test",
            detail: "Test preset",
            hero: "test",
            defaultFormat: .jpeg,
            defaultQuality: 80,
            defaultResizePercent: 50,
            preserveMetadata: true
        )
        
        let form = preset.makeForm()
        #expect(form.resizeEnabled == true)
        #expect(form.resizePercent == 50)
    }
    
    @Test("Preset filename suffix matches format")
    func testPresetFilenameSuffix() {
        for preset in ConversionPreset.defaults {
            let form = preset.makeForm()
            let expectedSuffix = "_\(preset.defaultFormat.fileExtension)"
            #expect(form.filenameSuffix == expectedSuffix)
        }
    }
    
    @Test("Presets have unique IDs")
    func testPresetUniqueIDs() {
        let preset1 = ConversionPreset.defaults.first!
        let preset2 = ConversionPreset.defaults.last!
        
        // Different presets should have different UUIDs
        if ConversionPreset.defaults.count > 1 {
            #expect(preset1.id != preset2.id)
        } else {
            // If only one preset, it equals itself
            #expect(preset1.id == preset1.id)
        }
    }
}
