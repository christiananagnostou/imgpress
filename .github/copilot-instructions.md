# ImgPress AI Coding Guide

## Core Principles

**Performance-First Development**: This project prioritizes optimal memory management, efficient UI state handling, minimal CPU/GPU overhead, algorithmic efficiency, and DRY code patterns to maintain a small bundle size. Every component is designed for speed and resource efficiency.

**AI Assistant Tools**: Use Context7 MCP for Apple SwiftUI documentation lookups. Use Sequential Thinking MCP for architectural changes and complex refactoring decisions.

**Code Clarity**: Write explicit, self-documenting code with clear naming. Add lightweight inline comments where logic requires explanation. Humans should immediately understand file organization, class responsibilities, function purposes, and variable meanings.

## Architecture Overview

ImgPress is a **macOS menu bar app** (not a window-based app) built with Swift 6/SwiftUI. Key architectural decisions:

- **NSApp.setActivationPolicy(.accessory)**: Lives in menu bar only, no dock icon
- **NSPopover**: UI appears as a 420×600 popover from menu bar, not a window
- **@MainActor AppState**: Single source of truth, owns all conversion jobs and form state
- **Component-based structure**: `/App`, `/Models`, `/Services`, `/Views/{Main,Components,MenuBar}`

The app initializes in `AppDelegate.applicationDidFinishLaunching()` → creates `AppState` → creates `MenuBarController` with popover → injects `ContentView` as popover content.

## File & Component Organization

**Strict directory structure** — files are organized by architectural layer, not feature:

```
Sources/ImgPressCore/
├── App/                    # App lifecycle (AppDelegate, AppState, ImgPressApp)
├── Models/                 # Data structures (ConversionModels, AppModels)
├── Services/              # Business logic (ConversionService, PresetManager, FileTypeValidator)
└── Views/
    ├── Main/              # Top-level views (ContentView, SettingsView, PresetEditorSheet)
    ├── Components/        # Reusable UI (ModernSegmentedControl, SliderControl, etc.)
    └── MenuBar/           # Menu bar specific (MenuBarController, StatusItemDropView)
```

**Naming conventions**:

- Files match their primary type: `ConversionService.swift` contains `ConversionService` class
- Components are named for their purpose: `ModernSegmentedControl` not `Selector`
- Functions use verb-noun pattern: `register(drop:)`, `queueConversion()`, `updateJob(_:mutate:)`
- Variables are descriptive: `importFoundCount` not `count`, `conversionStatusMessage` not `status`

**Component extraction rules**:

- Extract when pattern appears 2+ times (DRY principle)
- Make generic over `T: Hashable` when possible (see `ModernSegmentedControl`)
- Place in `Views/Components/` only if reusable across multiple parent views
- Keep components focused: 30-100 lines ideal, never exceed 150 lines

## Critical Workflows

### Build & Test

```bash
swift build              # Debug build
swift test               # Run 84 tests (ConversionModels, Service, AppState, etc.)
swift run ImgPress       # Launch menu bar app
```

**Important**: Tests use Swift Testing framework (`@Suite`, `@Test`, `#expect`), not XCTest.

### Development Pattern

1. All model structs must be `Sendable` (Swift 6 strict concurrency enabled)
2. UI components in `Views/Components/` must be generic and reusable
3. State updates happen via `AppState` methods, never direct property mutation
4. Package.swift enforces `-warnings-as-errors` in debug mode

## Core Data Flow

**Drag & Drop → Batch Conversion**:

1. User drops files on `StatusItemDropView` (menu bar icon) or `ContentView` empty state
2. `AppState.register(drop:)` runs **off main thread** to scan/validate files via `FileTypeValidator`
3. Valid files become `ConversionJob` instances with `.pending` status
4. User clicks "Convert All" → `AppState.queueConversion()` iterates jobs:
   - Updates job status: `.inProgress(step)` → `.completed(result)` or `.failed(error)`
   - Calls `ConversionService.convert()` which uses ImageIO framework directly (no dependencies)
5. Results accumulate in `ConversionSummary` for batch stats

**Key insight**: `AppState` is `@MainActor` but delegates heavy work to `Task.detached` to avoid blocking UI.

## Project-Specific Conventions

### Preset System (Unified Model)

- **Single `Preset` struct** for both default and custom presets (no ConversionPreset/UserPreset split)
- Properties: `id`, `name`, `description`, `icon` (SF Symbol name), `format`, `quality`, `resizePercent`, `preserveMetadata`
- `Preset.defaults` = hardcoded array of 3 presets (Shareable JPEG, Transparent PNG, High-efficiency AVIF)
- Custom presets stored via `PresetManager` in UserDefaults as JSON
- `Preset.makeForm()` converts preset → `ConversionForm` for actual conversion

### Reusable UI Components Pattern

Components in `Views/Components/` follow a strict pattern:

**ModernSegmentedControl.swift** (81 lines):

- Generic over `T: Hashable`, uses provider closures for flexibility
- `titleProvider: (T) -> String` and `iconProvider: ((T) -> String?)?` for on-demand computation
- Stores only `[T]` array, not duplicate metadata (memory optimization)
- Convenience init with tuple syntax: `[(value: T, title: String, icon: String?)]`
- Uses `@Namespace` + `matchedGeometryEffect` for sliding animation
- **Never** create new IDs in body (use `ForEach(options, id: \.self)`)

**SliderControl.swift** (30 lines):

- Reusable slider with label, icon, and percentage display
- Parameters: `title`, `icon`, `value: Binding<Double>`, `range`, `step`, `tintColor`, `valueColor`
- Used in `ConversionSettingsSection` for quality and resize controls

### File Type Validation

`FileTypeValidator.supportedTypes` uses UTType conformance, not extension checks:

- Supports `.image`, `.rawImage`, Canon CR2/CR3, DNG, HEIC, etc.
- **Why**: RAW formats have inconsistent extensions; UTType is canonical

### Format Support & Platform Detection

`ImageFormat.cgImageUTType` (private extension in `ConversionService.swift`):

- **WebP**: Always use `"org.webmproject.webp"` identifier (macOS 11+)
- **AVIF**: Check `#available(macOS 13, *)` before using `"public.avif"`
- **Error handling**: Throw `.destinationCreationFailed` if format unsupported on user's OS

## State Management Patterns

### AppState Publishing

- Use `@Published` for UI-bound properties (`jobs`, `conversionForm`, `conversionResult`)
- Use plain properties for internal state (like `conversionTask: Task<Void, Never>?`)
- Never expose `ConversionService` or `PresetManager` instances directly

### Thumbnail Caching

`ThumbnailCache.shared` uses thread-safe `NSLock` wrapper (`@unchecked Sendable`):

- LRU eviction when cache exceeds 100 items
- `clearCache()` called in `AppState.register(drop:)` to free memory on new import
- **Don't** generate thumbnails in `body` — cache them in model layer

### Conversion Job Updates

Pattern for updating individual jobs in array:

```swift
private func updateJob(_ id: UUID, mutate: (inout ConversionJob) -> Void) {
    guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
    mutate(&jobs[index])
}
```

This triggers single SwiftUI update via `@Published`, not array replacement.

## Integration Points

### External Dependencies

**None** — project uses only Apple frameworks:

- `ImageIO`: Image reading/writing (supports JPEG, PNG, WebP, AVIF, RAW)
- `UniformTypeIdentifiers`: File type detection
- `AppKit`: Menu bar integration (`NSStatusBar`, `NSPopover`)

### Cross-Component Communication

- **AppState ↔ PresetManager**: AppState owns `PresetManager` instance, exposes as `let`
- **PresetSelector ↔ PresetEditorSheet**: Callback closure pattern `(String, String, String, ConversionForm) -> Void`
- **ContentView ↔ AppState**: Environment object injection via `@EnvironmentObject`

### Menu Bar Integration

`MenuBarController` creates `NSStatusItem` with custom `StatusItemDropView`:

- Handles drag-and-drop directly on menu bar icon
- Shows popover on click via `popover.show(relativeTo:of:preferredEdge:)`
- **Critical**: Must retain strong reference to `NSStatusItem` or it disappears

## Testing Conventions

- **Suite naming**: Use `@Suite("Feature Name")` for logical grouping
- **Parameterized tests**: Use `@Test(arguments: [...])` for testing multiple values
- **Sendable conformance**: All model types must pass strict concurrency checks
- **No mocking**: Test actual logic, use dependency injection only for `PresetManager(userDefaults:)`

Example from `ConversionModelsTests.swift`:

```swift
@Suite("ImageFormat") struct ImageFormatTests {
    @Test("All formats have unique extensions")
    func uniqueExtensions() {
        let extensions = ImageFormat.allCases.map(\.fileExtension)
        #expect(Set(extensions).count == extensions.count)
    }
}
```

## Performance Guidelines

**Memory Management**:

- Static formatters: Create `ByteCountFormatter` once, reuse across views
- Thumbnail caching: `ThumbnailCache.shared` uses LRU eviction at 100 items, `NSLock` for thread safety
- Clear caches: Call `clearCache()` on new imports to prevent unbounded growth
- Avoid body allocations: Never create formatters, managers, or services in SwiftUI `body`

**UI State Optimization**:

- Batch updates: `importFoundCount` updates every 20 files during scan, not per-file
- Display windowing: Show first 50 jobs only, indicate "+X more" for remaining items
- Selective publishing: Use `@Published` only for UI-bound properties, plain properties for internal state
- Targeted mutations: `updateJob(_:mutate:)` modifies single array element, triggers one SwiftUI update

**CPU/GPU Efficiency**:

- Off-main-thread work: Heavy operations in `Task.detached` (file scanning, conversion)
- O(1) lookups: Dictionary-based lookups in `ModernSegmentedControl` convenience init
- Thumbnail limits: 40×40 pixels max via `maxDimension` parameter
- Computed geometry: Use `matchedGeometryEffect` for animations, not manual frame calculations

**Bundle Size & Code Quality**:

- Zero dependencies: Apple frameworks only (ImageIO, UniformTypeIdentifiers, AppKit)
- DRY extraction: Shared logic in reusable components (ModernSegmentedControl, SliderControl)
- Generic components: Type-parameterized over `T: Hashable` reduces code duplication
- Provider closures: Store data once, compute views on-demand (titleProvider, iconProvider)

## Common Pitfalls

- **Don't** call `swift test 2>&1 | tail -3` — shows only last 3 lines, hides failures
- **Don't** add dependencies — project is intentionally zero-dependency
- **Don't** create windows/sheets for settings — use `NSPopover` for menu bar app UX
- **Don't** forget `@MainActor` on view models — required for `@Published` properties
