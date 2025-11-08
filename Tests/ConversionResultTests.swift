import Testing
import Foundation
@testable import ImgPressCore

@Suite("ConversionResult Tests")
struct ConversionResultTests {
    
    @Test("Percent change calculation for reduction")
    func testPercentChangeReduction() {
        let result = ConversionResult(
            originalSize: 1000,
            outputSize: 750,
            outputURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            duration: 1.0
        )
        
        #expect(result.percentChange == -25.0)
    }
    
    @Test("Percent change calculation for increase")
    func testPercentChangeIncrease() {
        let result = ConversionResult(
            originalSize: 1000,
            outputSize: 1500,
            outputURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            duration: 1.0
        )
        
        #expect(result.percentChange == 50.0)
    }
    
    @Test("Percent change handles zero original size")
    func testPercentChangeZeroOriginal() {
        let result = ConversionResult(
            originalSize: 0,
            outputSize: 100,
            outputURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            duration: 1.0
        )
        
        #expect(result.percentChange == 0.0)
    }
    
    @Test("Size delta calculation")
    func testSizeDelta() {
        let result = ConversionResult(
            originalSize: 1000,
            outputSize: 750,
            outputURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            duration: 1.0
        )
        
        #expect(result.sizeDelta == -250)
    }
    
    @Test("IsSmaller flag when output is smaller")
    func testIsSmallerWhenReduced() {
        let result = ConversionResult(
            originalSize: 1000,
            outputSize: 750,
            outputURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            duration: 1.0
        )
        
        #expect(result.isSmaller == true)
    }
    
    @Test("IsSmaller flag when output is equal")
    func testIsSmallerWhenEqual() {
        let result = ConversionResult(
            originalSize: 1000,
            outputSize: 1000,
            outputURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            duration: 1.0
        )
        
        #expect(result.isSmaller == true)
    }
    
    @Test("IsSmaller flag when output is larger")
    func testIsSmallerWhenLarger() {
        let result = ConversionResult(
            originalSize: 1000,
            outputSize: 1500,
            outputURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            duration: 1.0
        )
        
        #expect(result.isSmaller == false)
    }
    
    @Test("ConversionResult is Sendable")
    func testResultIsSendable() async {
        let result = ConversionResult(
            originalSize: 1000,
            outputSize: 750,
            outputURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            duration: 1.0
        )
        
        await Task.detached {
            _ = result.percentChange
        }.value
    }
    
    @Test("ConversionResult is Equatable")
    func testResultEquality() {
        let url = URL(fileURLWithPath: "/tmp/test.jpg")
        let result1 = ConversionResult(
            originalSize: 1000,
            outputSize: 750,
            outputURL: url,
            duration: 1.0
        )
        let result2 = ConversionResult(
            originalSize: 1000,
            outputSize: 750,
            outputURL: url,
            duration: 1.0
        )
        
        #expect(result1 == result2)
    }
}
