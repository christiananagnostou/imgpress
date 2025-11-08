import AppKit

extension NSImage {
    /// Resize image to fit within a maximum dimension while preserving aspect ratio
    func resized(toMaxDimension maxDimension: CGFloat) -> NSImage {
        let aspectRatio = size.width / size.height
        let newSize: NSSize
        
        if size.width > size.height {
            newSize = NSSize(
                width: min(maxDimension, size.width),
                height: min(maxDimension, size.width) / aspectRatio
            )
        } else {
            newSize = NSSize(
                width: min(maxDimension, size.height) * aspectRatio,
                height: min(maxDimension, size.height)
            )
        }
        
        guard newSize != size else { return self }
        
        let resized = NSImage(size: newSize, flipped: false) { bounds in
            self.draw(in: bounds, from: .zero, operation: .copy, fraction: 1.0)
            return true
        }
        
        return resized
    }
}
