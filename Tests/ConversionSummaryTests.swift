import Testing
import Foundation
@testable import ImgPressCore

@Suite("ConversionSummary Tests")
struct ConversionSummaryTests {
    
    @Test("Total size delta calculation")
    func testTotalSizeDelta() {
        let summary = ConversionSummary(
            totalFiles: 10,
            completedCount: 10,
            failedCount: 0,
            totalOriginalSize: 10000,
            totalOutputSize: 7500,
            duration: 5.0
        )
        
        #expect(summary.totalSizeDelta == -2500)
    }
    
    @Test("Percent change calculation")
    func testPercentChange() {
        let summary = ConversionSummary(
            totalFiles: 10,
            completedCount: 10,
            failedCount: 0,
            totalOriginalSize: 10000,
            totalOutputSize: 7500,
            duration: 5.0
        )
        
        #expect(summary.percentChange == -25.0)
    }
    
    @Test("Percent change handles zero original size")
    func testPercentChangeZeroOriginal() {
        let summary = ConversionSummary(
            totalFiles: 0,
            completedCount: 0,
            failedCount: 0,
            totalOriginalSize: 0,
            totalOutputSize: 100,
            duration: 0.0
        )
        
        #expect(summary.percentChange == 0.0)
    }
    
    @Test("IsSmaller flag when reduced")
    func testIsSmallerWhenReduced() {
        let summary = ConversionSummary(
            totalFiles: 10,
            completedCount: 10,
            failedCount: 0,
            totalOriginalSize: 10000,
            totalOutputSize: 7500,
            duration: 5.0
        )
        
        #expect(summary.isSmaller == true)
    }
    
    @Test("IsSmaller flag when larger")
    func testIsSmallerWhenLarger() {
        let summary = ConversionSummary(
            totalFiles: 10,
            completedCount: 10,
            failedCount: 0,
            totalOriginalSize: 10000,
            totalOutputSize: 15000,
            duration: 5.0
        )
        
        #expect(summary.isSmaller == false)
    }
    
    @Test("Average time per file calculation")
    func testAverageTimePerFile() {
        let summary = ConversionSummary(
            totalFiles: 10,
            completedCount: 10,
            failedCount: 0,
            totalOriginalSize: 10000,
            totalOutputSize: 7500,
            duration: 10.0
        )
        
        #expect(summary.averageTimePerFile == 1.0)
    }
    
    @Test("Average time per file handles zero files")
    func testAverageTimePerFileZeroFiles() {
        let summary = ConversionSummary(
            totalFiles: 0,
            completedCount: 0,
            failedCount: 0,
            totalOriginalSize: 0,
            totalOutputSize: 0,
            duration: 10.0
        )
        
        #expect(summary.averageTimePerFile == 0.0)
    }
    
    @Test("Summary tracks failed conversions")
    func testFailedCount() {
        let summary = ConversionSummary(
            totalFiles: 10,
            completedCount: 7,
            failedCount: 3,
            totalOriginalSize: 10000,
            totalOutputSize: 7500,
            duration: 5.0
        )
        
        #expect(summary.failedCount == 3)
        #expect(summary.completedCount == 7)
    }
}
