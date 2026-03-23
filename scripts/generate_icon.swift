import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first
let outputDirectory = URL(fileURLWithPath: outputPath ?? "./dist/AppIcon.iconset", isDirectory: true)

let sizes: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(origin: .zero, size: NSSize(width: size, height: size))

    NSColor(calibratedRed: 0.83, green: 0.78, blue: 0.69, alpha: 1).setFill()
    NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22).fill()

    let frame = NSRect(x: size * 0.12, y: size * 0.12, width: size * 0.76, height: size * 0.76)
    NSColor(calibratedRed: 0.28, green: 0.31, blue: 0.27, alpha: 1).setStroke()
    let framePath = NSBezierPath(roundedRect: frame, xRadius: size * 0.08, yRadius: size * 0.08)
    framePath.lineWidth = max(2, size * 0.035)
    framePath.stroke()

    let photoRect = NSRect(x: size * 0.20, y: size * 0.30, width: size * 0.60, height: size * 0.46)
    NSColor(calibratedRed: 0.95, green: 0.93, blue: 0.87, alpha: 1).setFill()
    NSBezierPath(roundedRect: photoRect, xRadius: size * 0.03, yRadius: size * 0.03).fill()

    let mountain = NSBezierPath()
    mountain.move(to: NSPoint(x: photoRect.minX + size * 0.03, y: photoRect.minY + size * 0.10))
    mountain.line(to: NSPoint(x: photoRect.minX + size * 0.20, y: photoRect.minY + size * 0.28))
    mountain.line(to: NSPoint(x: photoRect.minX + size * 0.30, y: photoRect.minY + size * 0.20))
    mountain.line(to: NSPoint(x: photoRect.minX + size * 0.43, y: photoRect.minY + size * 0.34))
    mountain.line(to: NSPoint(x: photoRect.minX + size * 0.58, y: photoRect.minY + size * 0.12))
    mountain.line(to: NSPoint(x: photoRect.maxX - size * 0.03, y: photoRect.minY + size * 0.10))
    mountain.line(to: NSPoint(x: photoRect.maxX - size * 0.03, y: photoRect.minY + size * 0.04))
    mountain.line(to: NSPoint(x: photoRect.minX + size * 0.03, y: photoRect.minY + size * 0.04))
    mountain.close()
    NSColor(calibratedRed: 0.44, green: 0.52, blue: 0.42, alpha: 1).setFill()
    mountain.fill()

    let sunRect = NSRect(x: photoRect.minX + size * 0.42, y: photoRect.maxY - size * 0.16, width: size * 0.11, height: size * 0.11)
    NSColor(calibratedRed: 0.79, green: 0.55, blue: 0.36, alpha: 1).setFill()
    NSBezierPath(ovalIn: sunRect).fill()

    let shredderBody = NSRect(x: size * 0.18, y: size * 0.15, width: size * 0.64, height: size * 0.12)
    NSColor(calibratedRed: 0.30, green: 0.36, blue: 0.29, alpha: 1).setFill()
    NSBezierPath(roundedRect: shredderBody, xRadius: size * 0.03, yRadius: size * 0.03).fill()

    let slotRect = NSRect(x: size * 0.24, y: size * 0.22, width: size * 0.52, height: size * 0.02)
    NSColor(calibratedWhite: 0.15, alpha: 1).setFill()
    NSBezierPath(roundedRect: slotRect, xRadius: size * 0.01, yRadius: size * 0.01).fill()

    for idx in 0..<8 {
        let x = size * 0.24 + CGFloat(idx) * size * 0.07
        let strip = NSRect(x: x, y: size * 0.05, width: size * 0.03, height: size * 0.10 + CGFloat(idx % 3) * size * 0.01)
        NSColor(calibratedRed: 0.95, green: 0.93, blue: 0.87, alpha: 1).setFill()
        NSBezierPath(roundedRect: strip, xRadius: size * 0.008, yRadius: size * 0.008).fill()
    }

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "PNG conversion failed"]) 
    }

    try png.write(to: url)
}

do {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    for item in sizes {
        let icon = drawIcon(size: CGFloat(item.size))
        let url = outputDirectory.appendingPathComponent(item.name)
        try writePNG(icon, to: url)
    }

    print("Generated iconset at \(outputDirectory.path)")
} catch {
    fputs("Icon generation failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
