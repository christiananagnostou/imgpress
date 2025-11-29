import AppKit
import UniformTypeIdentifiers

/// Custom view that handles drag-and-drop operations and click events for the menu bar status item
final class StatusItemDropView: NSView {
    var onClick: (() -> Void)?
    var onPerformDrop: (([URL]) -> Void)?
    var onDraggingHighlight: ((Bool) -> Void)?

    private var isDragInside = false {
        didSet {
            guard oldValue != isDragInside else { return }
            onDraggingHighlight?(isDragInside)
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        registerForDraggedTypes([.fileURL])
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return self
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard containsAcceptableFile(in: sender) else {
            isDragInside = false
            return []
        }

        isDragInside = true
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        containsAcceptableFile(in: sender) ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragInside = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        defer { isDragInside = false }
        let urls = fileURLs(from: sender)
        guard !urls.isEmpty else { return false }
        onPerformDrop?(urls)
        return true
    }

    private func fileURLs(from draggingInfo: NSDraggingInfo) -> [URL] {
        let pasteboard = draggingInfo.draggingPasteboard
        return pasteboard.readObjects(
            forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }

    private func containsAcceptableFile(in draggingInfo: NSDraggingInfo) -> Bool {
        let urls = fileURLs(from: draggingInfo)
        return urls.contains { url in
            // Accept if the URL is an acceptable image file
            if FileTypeValidator.isAcceptable(url) {
                return true
            }
            // Accept if the URL is a directory (AppState.flattenURLs will handle recursion)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                return isDirectory.boolValue
            }
            return false
        }
    }
}
