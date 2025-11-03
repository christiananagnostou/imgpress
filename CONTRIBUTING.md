## Contributing to Rebar

Thanks for taking the time to contribute! This project aims to be a polished, open-source macOS menu bar companion for converting and optimizing images. To keep the experience smooth for everyone, please follow the workflow below.

### Getting Started

1. **Prerequisites**
   - macOS 13 Ventura or newer.
   - Xcode 15 (or newer) with the command-line tools installed:  
     `sudo xcode-select --switch /Applications/Xcode.app`
   - Node.js (for the Squoosh CLI) and ExifTool when you begin working on conversion features.

2. **Cloning & first run**
   ```bash
   git clone https://github.com/<your-user>/rebar.git
   cd rebar
   swift run Rebar
   ```
   The menu bar icon (`camera.aperture` or `Reb`) should appear; click it to open the SwiftUI popover.

### Branching & Pull Requests

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/amazing-improvement
   ```
2. Keep commits small and focused.
3. Run the app and (when applicable) conversion tests before you push.
4. Open a pull request with:
   - A short summary of the change.
   - Screenshots or screen recordings for UI changes.
   - Notes about testing, edge cases, or follow-up work.

### Coding Standards

- Swift code follows the Swift API Design Guidelines, with types organized by feature (`MenuBarController`, `AppState`, etc.).
- Use `@MainActor` for UI-facing objects and hop to background queues for long-running conversion work.
- Prefer `NSLog` for diagnostics that users may need when troubleshooting.
- Add focused comments only when the intent is not immediately obvious.

### Testing

- Manual UI/UX verification is required for menu bar behavior (status item presence, drag-and-drop).
- Unit tests should cover new business logic or preset parsing when we move conversion pipelines into dedicated services.

### Reporting Issues

Please include:
- macOS version and hardware (e.g. “macOS Sonoma 14.2, M2 Pro”).
- Steps to reproduce.
- Console logs (`Console.app` → filter for “Rebar”) if the app fails to show in the menu bar.
- Screenshots when helpful.

### Code of Conduct

Be kind, be respectful, and remember that everyone is here to build something helpful. Harassment or discriminatory language will not be tolerated.

Happy building!
