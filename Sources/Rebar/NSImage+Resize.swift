import AppKit

extension NSImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> NSImage {
        guard let representation = bestRepresentation(for: NSRect(origin: .zero, size: size), context: nil, hints: nil) else {
            return self
        }

        let aspectWidth = maxDimension / size.width
        let aspectHeight = maxDimension / size.height
        let ratio = min(aspectWidth, aspectHeight, 1)

        let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
        let image = NSImage(size: newSize)
        image.lockFocus()
        representation.draw(in: NSRect(origin: .zero, size: newSize))
        image.unlockFocus()
        image.size = newSize
        return image
    }
}
