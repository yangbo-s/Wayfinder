import AppKit

/// A template version of the App icon: the same folder and right-turn path,
/// without the tile, color or depth that disappear at menu-bar sizes.
enum WayfinderSymbol {
    static func image(size: CGFloat = 20) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }
            let transform = NSAffineTransform()
            transform.scale(by: size / 22)
            transform.concat()

            let folder = NSBezierPath()
            folder.move(to: NSPoint(x: 2, y: 3))
            folder.line(to: NSPoint(x: 20, y: 3))
            folder.line(to: NSPoint(x: 20, y: 16))
            folder.line(to: NSPoint(x: 10, y: 16))
            folder.line(to: NSPoint(x: 7.5, y: 18.5))
            folder.line(to: NSPoint(x: 2, y: 18.5))
            folder.close()
            folder.lineWidth = 1.4
            folder.lineJoinStyle = .round
            NSColor.black.withAlphaComponent(0.7).setStroke()
            folder.stroke()

            let arrow = NSBezierPath()
            arrow.move(to: NSPoint(x: 7, y: 13))
            arrow.line(to: NSPoint(x: 7, y: 10.5))
            arrow.curve(to: NSPoint(x: 8.5, y: 9),
                controlPoint1: NSPoint(x: 7, y: 9.5), controlPoint2: NSPoint(x: 7.5, y: 9))
            arrow.line(to: NSPoint(x: 16, y: 9))
            arrow.move(to: NSPoint(x: 13, y: 12))
            arrow.line(to: NSPoint(x: 16, y: 9))
            arrow.line(to: NSPoint(x: 13, y: 6))
            arrow.lineWidth = 1.8
            arrow.lineCapStyle = .round
            arrow.lineJoinStyle = .round
            NSColor.black.setStroke()
            arrow.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Wayfinder"
        return image
    }
}
