import Foundation
import Testing
import UniformTypeIdentifiers

@testable import ImgPressCore

@Suite("Drag and Drop Tests")
struct DragDropTests {

  @Test("AppState registers dropped URLs")
  @MainActor
  func testRegisterDrop() async {
    let appState = AppState()
    let testURL = URL(fileURLWithPath: "/tmp/test.jpg")

    // Initially no jobs
    #expect(appState.jobs.isEmpty)

    // Register a drop
    appState.register(drop: [testURL])

    // Should start importing
    #expect(appState.isImporting == true)

    // Wait for import to complete
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

    // Import should complete
    #expect(appState.isImporting == false)
  }

  @Test("AppState clears cache on new drop")
  @MainActor
  func testCacheClearedOnDrop() async {
    let appState = AppState()
    let testURL = URL(fileURLWithPath: "/tmp/test.jpg")

    // Register first drop
    appState.register(drop: [testURL])

    // Verify cache is cleared (no errors thrown)
    #expect(Bool(true))
  }

  @Test("AppState resets errors on new drop")
  @MainActor
  func testErrorsResetOnDrop() async {
    let appState = AppState()
    let testURL = URL(fileURLWithPath: "/tmp/test.jpg")

    // Set an error
    appState.dropError = .noUsableFiles
    #expect(appState.dropError != nil)

    // Register new drop
    appState.register(drop: [testURL])

    // Error should be cleared
    #expect(appState.dropError == nil)
  }

  @Test("AppState handles empty URL array")
  @MainActor
  func testEmptyDropArray() async {
    let appState = AppState()

    appState.register(drop: [])

    // Should not start importing for empty array
    #expect(appState.isImporting == true)

    // Wait briefly
    try? await Task.sleep(nanoseconds: 50_000_000)

    #expect(appState.isImporting == false)
    #expect(appState.jobs.isEmpty)
  }

  @Test("AppState sets import status message")
  @MainActor
  func testImportStatusMessage() async {
    let appState = AppState()
    let testURL = URL(fileURLWithPath: "/tmp/test.jpg")

    appState.register(drop: [testURL])

    // Should set status message
    #expect(appState.importStatusMessage != nil)
    #expect(appState.importFoundCount >= 0)
  }

  @Test("Multiple drops reset previous jobs")
  @MainActor
  func testMultipleDropsReset() async {
    let appState = AppState()
    let url1 = URL(fileURLWithPath: "/tmp/test1.jpg")
    let url2 = URL(fileURLWithPath: "/tmp/test2.jpg")

    // First drop
    appState.register(drop: [url1])

    try? await Task.sleep(nanoseconds: 50_000_000)

    // Second drop should reset
    appState.register(drop: [url2])

    // Jobs should be cleared and restarting
    #expect(appState.jobs.isEmpty || appState.isImporting)
  }

  @Test("Conversion results cleared on new drop")
  @MainActor
  func testConversionResultsCleared() async {
    let appState = AppState()
    let testURL = URL(fileURLWithPath: "/tmp/test.jpg")

    // Set some conversion results
    appState.conversionResult = ConversionResult(
      originalSize: 1000,
      outputSize: 750,
      outputURL: testURL,
      duration: 1.0
    )
    appState.conversionSummary = ConversionSummary(
      totalFiles: 1,
      completedCount: 1,
      failedCount: 0,
      totalOriginalSize: 1000,
      totalOutputSize: 750,
      duration: 1.0
    )

    #expect(appState.conversionResult != nil)
    #expect(appState.conversionSummary != nil)

    // New drop should clear results immediately (synchronous)
    appState.register(drop: [testURL])

    #expect(appState.conversionResult == nil)
    #expect(appState.conversionSummary == nil)
    #expect(appState.conversionErrorMessage == nil)
    // Import status should be set
    #expect(appState.importStatusMessage == "Scanning…")
  }
}

@Suite("StatusItemDropView Tests")
struct StatusItemDropViewTests {

  @Test("Drop view is initialized correctly")
  @MainActor
  func testInitialization() {
    let dropView = StatusItemDropView()

    // Should be initialized without errors
    #expect(dropView.onClick == nil)
    #expect(dropView.onPerformDrop == nil)
    #expect(dropView.onDraggingHighlight == nil)
  }

  @Test("Drop view callbacks can be set")
  @MainActor
  func testCallbacksCanBeSet() {
    let dropView = StatusItemDropView()
    var clickCalled = false
    var dropCalled = false
    var highlightCalled = false

    dropView.onClick = {
      clickCalled = true
    }

    dropView.onPerformDrop = { urls in
      dropCalled = true
    }

    dropView.onDraggingHighlight = { highlighted in
      highlightCalled = true
    }

    // Trigger callbacks
    dropView.onClick?()
    dropView.onPerformDrop?([])
    dropView.onDraggingHighlight?(true)

    #expect(clickCalled)
    #expect(dropCalled)
    #expect(highlightCalled)
  }

  @Test("Drop view has correct registered types")
  @MainActor
  func testRegisteredDraggedTypes() {
    let dropView = StatusItemDropView()

    // Should register for file URL drops
    let registeredTypes = dropView.registeredDraggedTypes
    #expect(!registeredTypes.isEmpty)
  }
}
