# Tests

Test suite for ImgPress core functionality.

## Running Tests

```bash
swift test                           # All tests
swift test --filter ImageFormat      # Specific suite
swift test --verbose                 # Detailed output
```

## Structure

```text
Tests/
├── ConversionModelsTests.swift      # ImageFormat, Form, Preset
├── ConversionResultTests.swift      # Result calculations
├── ConversionSummaryTests.swift     # Batch summaries
├── ConversionServiceTests.swift     # Service & errors
├── ConversionStageTests.swift       # Progress stages
├── FileTypeValidatorTests.swift     # File validation
└── AppStateTests.swift              # Cache, JobStatus, Errors
```

## Writing Tests

```swift
import Testing
@testable import ImgPressCore

@Suite("My Feature")
struct MyTests {
    @Test("Description")
    func testFeature() {
        #expect(value == expected)
    }
    
    // Parameterized
    @Test(arguments: [1, 2, 3])
    func testMultiple(num: Int) {
        #expect(num > 0)
    }
}
```

## Coverage

- ✅ Models & calculations
- ✅ Error handling
- ✅ Thread safety (Swift 6)
- ✅ Edge cases
- ✅ Format support

See [TESTING.md](../TESTING.md) for details.
