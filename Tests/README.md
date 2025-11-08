# ImgPress Testing Suite

This project uses **Swift Testing**, the modern testing framework introduced in Swift 5.9+. The test suite provides comprehensive coverage of the core business logic.

## Running Tests

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test suite
swift test --filter ConversionServiceTests

# Run with parallel execution disabled (for debugging)
swift test --parallel
```

## Test Structure

The tests are organized by functionality:

### Core Model Tests
- **ConversionModelsTests.swift** - Tests for `ImageFormat`, `ConversionForm`, and `ConversionPreset`
- **ConversionResultTests.swift** - Tests for conversion result calculations and properties
- **ConversionSummaryTests.swift** - Tests for batch conversion summaries

### Service Tests
- **ConversionServiceTests.swift** - Tests for the conversion service and error handling
- **ConversionServiceErrorTests.swift** - Error message and Sendable conformance tests
- **FileTypeValidatorTests.swift** - File type validation logic tests

### UI State Tests
- **AppStateTests.swift** - Tests for `ThumbnailCache`, `ConversionJobStatus`, and `DropError`
- **ConversionStageTests.swift** - Tests for conversion progress stages

## Test Coverage

The test suite covers:

✅ **Data Models** - All model calculations and transformations  
✅ **Sendable Conformance** - Swift 6 concurrency safety  
✅ **Thread Safety** - Multi-threaded access patterns  
✅ **Error Handling** - All error cases and messages  
✅ **Edge Cases** - Zero values, empty collections, etc.  
✅ **Format Support** - JPEG, PNG, WebP, and AVIF  

## Swift Testing Features Used

### Modern Assertions
```swift
#expect(value == expected)  // Replaces XCTAssertEqual
#expect(condition)          // Replaces XCTAssertTrue
```

### Parameterized Tests
```swift
@Test("Test name", arguments: [.jpeg, .png, .webp, .avif])
func testWithMultipleFormats(format: ImageFormat) {
    // Test runs once for each format
}
```

### Test Suites
```swift
@Suite("GroupName")
struct MyTests {
    // Related tests grouped together
}
```

### Async Testing
```swift
@Test("Async test")
func testAsync() async {
    await someAsyncOperation()
    #expect(result == expected)
}
```

## Adding New Tests

1. Create a new test file in the `Tests/` directory
2. Import the testing framework and module:
   ```swift
   import Testing
   @testable import ImgPressCore
   ```
3. Create a test suite:
   ```swift
   @Suite("Feature Tests")
   struct FeatureTests {
       @Test("Test description")
       func testFeature() {
           #expect(condition)
       }
   }
   ```

## Best Practices

- ✅ Use descriptive test names
- ✅ Test one thing per test function
- ✅ Use parameterized tests for similar cases
- ✅ Mark concurrent tests with `async` when needed
- ✅ Test Sendable conformance for concurrent types
- ✅ Test edge cases (zero, nil, empty, etc.)

## CI/CD Integration

To integrate with CI/CD pipelines:

```bash
# Run tests with failure output
swift test --parallel || exit 1

# Generate test results (requires Xcode)
xcodebuild test -scheme ImgPress -destination 'platform=macOS'
```

## Concurrency Testing

The test suite validates Swift 6 strict concurrency:
- All `Sendable` types are tested for thread safety
- Concurrent access patterns are validated
- Data races are prevented through proper isolation

## Performance Considerations

Tests are designed to be fast:
- No actual image processing (uses mock data)
- Minimal file I/O operations
- Parallel test execution enabled by default
