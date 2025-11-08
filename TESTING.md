# Testing

> Comprehensive test suite using Swift Testing framework (Swift 5.9+)

## Quick Start

```bash
swift test                              # Run all tests
swift test --filter ImageFormatTests    # Run specific suite
swift test --verbose                    # Detailed output
```

## Coverage

**62 tests across 14 suites** covering all core business logic and UI interactions.

<details>
<summary>Test Breakdown</summary>

| Suite | Tests | Coverage |
|-------|-------|----------|
| ImageFormat | 4 | Extensions, quality, identifiers |
| ConversionForm | 3 | Defaults, formats, Sendable |
| ConversionPreset | 5 | Generation, resize settings |
| ConversionResult | 8 | Calculations, deltas, equality |
| ConversionSummary | 7 | Aggregations, statistics |
| ConversionService | 2 | Thread safety, Sendable |
| ConversionServiceError | 4 | Error messages |
| ConversionStage | 5 | Labels, uniqueness |
| FileTypeValidator | 3 | Type conformance |
| ThumbnailCache | 3 | Singleton, thread safety |
| ConversionJobStatus | 4 | State transitions |
| DropError | 2 | Error descriptions |
| DragDrop | 7 | Drop handling, state resets |
| StatusItemDropView | 3 | Callbacks, initialization |

</details>

## Swift Testing Features

Modern syntax replacing XCTest:

```swift
// Modern assertions
#expect(value == expected)

// Parameterized tests
@Test("Test name", arguments: [.jpeg, .png, .webp])
func testFormats(format: ImageFormat) { }

// Test suites
@Suite("Feature Tests")
struct FeatureTests { }

// Async support
@Test func testAsync() async { }
```

## Key Benefits

- ✅ Swift 6 concurrency validation
- ✅ Thread safety verification
- ✅ Fast execution (~3ms for full suite)
- ✅ CI/CD ready
- ✅ Parameterized test support

## Adding Tests

1. Create file in `Tests/`
2. Import framework:

   ```swift
   import Testing
   @testable import ImgPressCore
   ```

3. Write tests:

   ```swift
   @Suite("My Tests")
   struct MyTests {
       @Test func feature() {
           #expect(condition)
       }
   }
   ```

## CI Integration

```bash
swift test --parallel || exit 1
```

---

**Status:** ✅ All tests passing
