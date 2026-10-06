import AppKit
let output = CommandLine.arguments[1]
let iconset = URL(fileURLWithPath: output).appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
// A code-native geometric mark: a folder tab and a right-turn path.
for (name, pixels) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = CGFloat(pixels) / 1024
    let transform = NSAffineTransform(); transform.scale(by: scale); transform.concat()
    NSColor(calibratedRed: 0.13, green: 0.29, blue: 0.41, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 198, yRadius: 198).fill()
    let folder = NSBezierPath()
    folder.move(to: NSPoint(x: 238,y: 645)); folder.line(to: NSPoint(x:238,y:727)); folder.line(to:NSPoint(x:435,y:727)); folder.line(to:NSPoint(x:490,y:672)); folder.line(to:NSPoint(x:786,y:672)); folder.line(to:NSPoint(x:786,y:295)); folder.line(to:NSPoint(x:238,y:295)); folder.close()
    NSColor.white.withAlphaComponent(0.28).setStroke(); folder.lineWidth = 38; folder.lineJoinStyle = .round; folder.stroke()
    let path = NSBezierPath(); path.move(to:NSPoint(x:368,y:607)); path.line(to:NSPoint(x:368,y:460)); path.curve(to:NSPoint(x:428,y:400), controlPoint1:NSPoint(x:368,y:417), controlPoint2:NSPoint(x:385,y:400)); path.line(to:NSPoint(x:666,y:400))
    path.move(to:NSPoint(x:577,y:491)); path.line(to:NSPoint(x:670,y:400)); path.line(to:NSPoint(x:577,y:309))
    NSColor.white.setStroke(); path.lineWidth = 54; path.lineCapStyle = .round; path.lineJoinStyle = .round; path.stroke()
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name + ".png"))
}
let task = Process(); task.executableURL = URL(fileURLWithPath:"/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", output + "/AppIcon.icns"]
try task.run(); task.waitUntilExit()
if task.terminationStatus != 0 { exit(task.terminationStatus) }
try FileManager.default.removeItem(at: iconset)
