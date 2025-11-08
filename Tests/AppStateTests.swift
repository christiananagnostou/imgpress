import Testing
import Foundation
@testable import ImgPressCore

@Suite("ThumbnailCache Tests")
struct ThumbnailCacheTests {
    
    @Test("Cache is a singleton")
    func testSingleton() {
        let cache1 = ThumbnailCache.shared
        let cache2 = ThumbnailCache.shared
        
        #expect(cache1 === cache2)
    }
    
    @Test("Cache conforms to Sendable")
    func testSendable() async {
        let cache = ThumbnailCache.shared
        
        await Task.detached {
            // If ThumbnailCache is properly Sendable, this compiles
            cache.clearCache()
        }.value
    }
    
    @Test("Clear cache is thread-safe")
    func testClearCacheThreadSafe() async {
        let cache = ThumbnailCache.shared
        
        // Clear from multiple threads simultaneously
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    cache.clearCache()
                }
            }
        }
        
        // Should complete without crashing
        #expect(Bool(true))
    }
}

@Suite("ConversionJobStatus Tests")
struct ConversionJobStatusTests {
    
    @Test("Status cases are equatable")
    func testStatusEquality() {
        let pending1 = ConversionJobStatus.pending
        let pending2 = ConversionJobStatus.pending
        
        #expect(pending1 == pending2)
        
        let url = URL(fileURLWithPath: "/tmp/test.jpg")
        let result = ConversionResult(
            originalSize: 1000,
            outputSize: 750,
            outputURL: url,
            duration: 1.0
        )
        
        let completed1 = ConversionJobStatus.completed(result)
        let completed2 = ConversionJobStatus.completed(result)
        
        #expect(completed1 == completed2)
    }
    
    @Test("Different statuses are not equal")
    func testDifferentStatusesNotEqual() {
        let pending = ConversionJobStatus.pending
        let inProgress = ConversionJobStatus.inProgress(step: .loadingInput)
        
        #expect(pending != inProgress)
    }
    
    @Test("In-progress statuses with same stage are equal")
    func testInProgressEquality() {
        let status1 = ConversionJobStatus.inProgress(step: .loadingInput)
        let status2 = ConversionJobStatus.inProgress(step: .loadingInput)
        
        #expect(status1 == status2)
    }
    
    @Test("Failed statuses with same message are equal")
    func testFailedEquality() {
        let status1 = ConversionJobStatus.failed("Error message")
        let status2 = ConversionJobStatus.failed("Error message")
        
        #expect(status1 == status2)
    }
}

@Suite("DropError Tests")
struct DropErrorTests {
    
    @Test("Error descriptions are user-friendly")
    func testErrorDescriptions() {
        #expect(DropError.noUsableFiles.errorDescription == "Drag a supported image file to get started.")
        #expect(DropError.securityScopedResourceDenied.errorDescription == "macOS denied access to the dropped file.")
        
        let testURL = URL(fileURLWithPath: "/tmp/test.jpg")
        let fileError = DropError.fileAccessFailed(testURL)
        #expect(fileError.errorDescription == "Could not access test.jpg.")
    }
    
    @Test("File access error includes filename")
    func testFileAccessErrorIncludesFilename() {
        let url = URL(fileURLWithPath: "/path/to/myimage.png")
        let error = DropError.fileAccessFailed(url)
        
        #expect(error.errorDescription?.contains("myimage.png") == true)
    }
}
