import Testing
import Foundation
@testable import ImgPressCore

@Suite("ConversionStage Tests")
struct ConversionStageTests {
    
    @Test("Raw values are descriptive")
    func testRawValues() {
        #expect(ConversionStage.ensuringOutputDirectory.rawValue == "Creating output directory")
        #expect(ConversionStage.loadingInput.rawValue == "Loading image")
        #expect(ConversionStage.resizing.rawValue == "Resizing")
        #expect(ConversionStage.writingOutput.rawValue == "Encoding")
        #expect(ConversionStage.finished.rawValue == "Completed")
    }
    
    @Test("Short labels are concise")
    func testShortLabels() {
        #expect(ConversionStage.ensuringOutputDirectory.shortLabel == "Dir")
        #expect(ConversionStage.loadingInput.shortLabel == "Load")
        #expect(ConversionStage.resizing.shortLabel == "Size")
        #expect(ConversionStage.writingOutput.shortLabel == "Encode")
        #expect(ConversionStage.finished.shortLabel == "Done")
    }
    
    @Test("All stages have unique raw values")
    func testUniqueRawValues() {
        let allStages: [ConversionStage] = [
            .ensuringOutputDirectory,
            .loadingInput,
            .resizing,
            .writingOutput,
            .finished
        ]
        
        let rawValues = Set(allStages.map { $0.rawValue })
        #expect(rawValues.count == allStages.count)
    }
    
    @Test("All stages have unique short labels")
    func testUniqueShortLabels() {
        let allStages: [ConversionStage] = [
            .ensuringOutputDirectory,
            .loadingInput,
            .resizing,
            .writingOutput,
            .finished
        ]
        
        let shortLabels = Set(allStages.map { $0.shortLabel })
        #expect(shortLabels.count == allStages.count)
    }
    
    @Test("ConversionStage is Sendable")
    func testStageIsSendable() async {
        let stage = ConversionStage.loadingInput
        
        await Task.detached {
            _ = stage.rawValue
        }.value
    }
}
