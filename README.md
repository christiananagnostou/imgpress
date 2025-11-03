# Rebar

Rebar is a macOS menu bar utility for image conversion and management. Drop an image onto the menu bar icon to open a focused command center for converting, compressing, or exporting in modern formats while keeping metadata intact.

## Current Snapshot

- Native status bar item that accepts drag-and-drop for broad image and raw formats (HEIC, RAW, AVIF, etc.).
- Popover management UI built with SwiftUI for reviewing the dropped asset and previewing conversion presets.
- Reactive `AppState` coordinator ready to orchestrate conversion pipelines and metadata handling.

> The project is in the “alpha” wiring stage—UI flows, queueing, and squoosh/exiftool integration are staged but not yet connected.

## Architecture Overview

| Layer | Key Types | Responsibilities |
| --- | --- | --- |
| Menu bar shell | `MenuBarController`, `StatusItemDropView` | Creates the status bar item, handles drag/drop validation, animates feedback, shows/hides the popover. |
| State & models | `AppState`, `DroppedItem`, `DropError` | Observable state container that registers accepted files, surfaces errors, and prepares metadata for the UI. |
| Presentation | `ContentView` (SwiftUI) | Displays the latest drop, placeholder conversion presets, and app chrome. |

The separation keeps AppKit-only code at the edges while the core logic and UI remain testable SwiftUI/Combine components. When we plug in conversion workflows we can do so via async tasks triggered from `AppState`.

## Roadmap Toward the Converter

1. **Conversion orchestration**  
   Hook the `MenuBarController` drop pathway into a dedicated conversion service that shells out to the existing Squoosh + ExifTool workflow. The intent is to keep “Presets” as high-level actions that translate to CLI invocations with preset parameters.

2. **Preset definitions**  
   Elevate the hard-coded presets to a data-driven model (e.g. `ConversionPreset` structs) describing codec, quality, resize, output directory, and metadata policy. Persist custom presets to disk later.

3. **Metadata bookkeeping**  
   Mirror the CLI’s metadata preservation by queueing a follow-up ExifTool step after Squoosh finishes, with structured progress + failure reporting in the UI.

4. **Queue & progress UI**  
   Support multiple drops by maintaining a conversion queue in `AppState`, highlighting in-progress, completed, and failed jobs.

5. **Distribution**  
   Wrap the executable in a proper `.app` bundle via `swift package` plugins or an Xcode project, add signing, sandbox entitlements (e.g. `com.apple.security.files.user-selected.read-write`), and deliver as a notarized universal build.

## Getting Started

### Prerequisites

- macOS 13 Ventura or newer.
- Xcode 15 (or newer) with command-line tools (`sudo xcode-select --switch /Applications/Xcode.app`).
- Optional (for future conversion features): Node.js 18+, `npx @frostoven/squoosh-cli`, `exiftool`, and `bc`.

### Build & Run

```bash
git clone https://github.com/YOUR-ORG/rebar.git
cd rebar
swift run Rebar
```

> If SwiftPM complains about cache locations, override them with  
> `SWIFT_MODULECACHE_PATH=.build/modulecache CLANG_MODULE_CACHE_PATH=.build/modulecache swift run Rebar`

While `swift run` is active, the Rebar status item (camera aperture symbol or “Reb”) appears on the macOS menu bar or inside the Control Center overflow. Click it to launch the SwiftUI popover.

To develop in a full app bundle, open `Package.swift` in Xcode (`open Package.swift`), choose the *Rebar* scheme, set the run destination to “My Mac”, and press **Run**. Xcode handles signing, archives, and `.app` generation for distribution.

## Prior CLI Inspiration

The original `squish` Zsh script (included in the prompt) drives the conversion pipeline via `npx @frostoven/squoosh-cli` and `exiftool`. Rebar will wrap the same tools behind a graphical preset system, allowing us to keep all the quality, resizing, and metadata-preservation guarantees while offering a more discoverable UX.

## Next Steps Checklist

- [ ] Model conversion presets and wire them to the placeholder buttons.
- [ ] Shell out to Squoosh CLI with progress callbacks.
- [ ] Copy metadata using ExifTool after conversion completes.
- [ ] Persist output locations and user preferences.
- [ ] Add lightweight telemetry/logging for debugging conversions.
- [ ] Replace SF Symbols icon with a custom template asset and notarize the app for distribution.
