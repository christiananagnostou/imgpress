# ImgPress

> A lightweight macOS menu bar app for batch image conversion and optimization.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Features

- **Menu Bar Native** - Lives in your menu bar with drag-and-drop support
- **Batch Processing** - Convert multiple images and folders simultaneously
- **Multiple Formats** - JPEG, PNG, WebP, and AVIF support
- **Real-time Stats** - Size comparison and conversion progress
- **Flexible Control** - Pause, resume, or stop conversions
- **Quick Presets** - Pre-configured workflows for common tasks
- **Custom Presets** - Save your favorite settings for instant reuse
- **RAW Support** - Handles CR2, CR3, DNG, and other camera formats

## Installation

```bash
git clone https://github.com/yourusername/imgpress.git
cd imgpress
swift build -c release
.build/release/ImgPress
```

## Usage

1. Click the menu bar icon (camera aperture)
2. Drag images or folders into the panel
3. Choose format and quality settings
4. Click Convert

### Quick Presets

Built-in presets for common workflows:

- **Shareable JPEG** - 75% quality, web-optimized
- **Transparent PNG** - Lossless, ideal for logos
- **High-efficiency AVIF** - Modern format, 45% smaller files

### Custom Presets

Save your favorite settings for instant reuse:

1. Configure your desired format, quality, resize, and options
2. Expand the **Quick Presets** section
3. Click **Save Current Settings**
4. Name your preset and click Create

Your custom presets appear below the default ones with a ⭐ icon. Manage them in Settings (⚙️):

- **Edit** - Update preset name or settings
- **Delete** - Swipe left or use delete key
- **Reorder** - Drag to change order
- **Auto-apply** - Toggle to apply first preset on launch


## Development

Built with Swift 6, SwiftUI, and Apple's ImageIO framework.

```bash
swift build          # Build debug version
swift test           # Run test suite
swift run ImgPress   # Launch app
```

See [TESTING.md](TESTING.md) for testing details.

## Requirements

- macOS 14.0+
- Swift 5.9+

## License

MIT - see [LICENSE](LICENSE) for details.
