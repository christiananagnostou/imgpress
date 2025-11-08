# Rebar

A lightweight macOS menu bar application for batch image conversion and optimization. Rebar lives in your menu bar and provides quick access to convert images between formats (JPEG, PNG, WebP, AVIF) with customizable quality and resize options.

## Features

- **Menu Bar Integration**: Quick access from your menu bar with drag-and-drop support
- **Batch Processing**: Convert multiple images at once, including entire folders
- **Multiple Formats**: Support for JPEG, PNG, WebP, and AVIF output formats
- **Smart Compression**: Adjustable quality settings with real-time size comparison
- **Resize Options**: Scale images by percentage while preserving aspect ratio
- **Quick Presets**: Pre-configured settings for common workflows
- **Advanced Controls**:
  - Pause, resume, or stop conversions in progress
  - Preserve or strip image metadata
  - Custom output directory and filename suffixes
- **Performance Optimized**: Efficient thumbnail generation and batch processing for large image sets
- **RAW Support**: Handles various RAW camera formats (CR2, CR3, etc.)

## Requirements

- macOS 14.0 or later
- Swift 5.9 or later

## Installation

### Build from Source

1. Clone the repository:

```bash
git clone https://github.com/yourusername/rebar.git
cd rebar
```

2. Build the application:

```bash
swift build -c release
```

3. The compiled executable will be at `.build/release/Rebar`

4. Copy to Applications or run directly:

```bash
.build/release/Rebar
```

## Usage

### Getting Started

1. Launch Rebar - it will appear in your menu bar as a camera aperture icon
2. Click the menu bar icon to open the conversion panel
3. Drag and drop images or folders onto the drop zone
4. Select your desired output format and quality settings
5. Click "Convert" to process your images

### Drag and Drop

You can drag images directly onto the menu bar icon without opening the panel. Rebar will automatically:

- Accept the files
- Open the panel
- Display the queued images ready for conversion

### Quick Presets

Rebar includes three optimized presets:

- **Shareable JPEG**: 75% quality, ideal for web sharing while preserving metadata
- **Transparent PNG**: Lossless compression, perfect for logos and graphics with transparency
- **High-efficiency AVIF**: Modern format with 45% smaller file sizes for compatible devices

### Advanced Options

- **Output Directory**: Choose where converted images are saved (defaults to Desktop/Rebar)
- **Filename Suffix**: Add custom suffixes to distinguish converted files
- **Metadata**: Toggle preservation of EXIF data, location info, and other metadata
- **Resize**: Scale images down by percentage for web optimization or storage

### Playback Controls

During batch conversions, use the playback controls to:

- **Pause**: Temporarily stop processing to free up system resources
- **Resume**: Continue from where you paused
- **Stop**: Cancel the remaining conversions (completed files are kept)

## How It Works

Rebar is built with Swift and SwiftUI, leveraging Apple's native ImageIO framework for efficient image processing. The application runs as a menu bar utility (LSUIElement) without a dock icon.

**Key Architecture:**

- **Efficient Thumbnails**: Uses CGImageSource to generate thumbnails without loading full images into memory, preventing memory issues with large batches
- **Batch Processing**: Processes files in the background while updating the UI every 20 files to keep the interface responsive
- **Display Limiting**: Only renders the first 50 items in large batches to maintain smooth scrolling
- **Format Support**: Leverages system-native codecs for JPEG, PNG, WebP (macOS 11+), and AVIF (macOS 13+)

## Supported File Types

**Input formats:**

- Standard images (JPEG, PNG, TIFF, BMP, GIF, etc.)
- RAW camera formats (CR2, CR3, Adobe DNG, etc.)
- HEIC/HEIF
- Live Photos
- QuickTime images

**Output formats:**

- JPEG
- PNG
- WebP
- AVIF

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please read CONTRIBUTING.md for guidelines on how to submit improvements and bug fixes.

## Acknowledgments

Built with Swift, SwiftUI, and Apple's ImageIO framework.
