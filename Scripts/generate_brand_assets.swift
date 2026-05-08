import AppKit
import Foundation

struct BrandPalette {
    static let night = NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.12, alpha: 1)
    static let slate = NSColor(calibratedRed: 0.10, green: 0.15, blue: 0.22, alpha: 1)
    static let ocean = NSColor(calibratedRed: 0.06, green: 0.55, blue: 0.92, alpha: 1)
    static let sky = NSColor(calibratedRed: 0.38, green: 0.84, blue: 0.98, alpha: 1)
    static let ember = NSColor(calibratedRed: 1.0, green: 0.47, blue: 0.20, alpha: 1)
    static let frost = NSColor(calibratedRed: 0.92, green: 0.97, blue: 1.0, alpha: 1)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsRoot = root.appendingPathComponent("BestBrowser/Assets.xcassets", isDirectory: true)
let iconSetURL = assetsRoot.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
let brandMarkURL = assetsRoot.appendingPathComponent("BrandMark.imageset", isDirectory: true)
let exportedBrandingURL = root.appendingPathComponent("BestBrowser/BrandingAssets", isDirectory: true)

try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: brandMarkURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: exportedBrandingURL, withIntermediateDirectories: true)

func drawBaseArtwork(in canvas: NSRect, insetScale: CGFloat = 0.1, includeWordmark: Bool = false) {
    let size = canvas.width
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let corner = size * 0.23
    let clip = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
    clip.addClip()

    let background = NSGradient(colors: [
        BrandPalette.night,
        BrandPalette.slate,
        BrandPalette.ocean.blended(withFraction: 0.2, of: BrandPalette.night) ?? BrandPalette.ocean
    ])!
    background.draw(in: rect, angle: -90)

    BrandPalette.sky.withAlphaComponent(0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: size * 0.12, y: size * 0.52, width: size * 0.76, height: size * 0.76)).fill()

    let frameRect = rect.insetBy(dx: size * insetScale, dy: size * insetScale)
    let framePath = NSBezierPath(roundedRect: frameRect, xRadius: size * 0.15, yRadius: size * 0.15)
    BrandPalette.frost.withAlphaComponent(0.10).setFill()
    framePath.fill()
    BrandPalette.sky.withAlphaComponent(0.78).setStroke()
    framePath.lineWidth = max(2, size * 0.018)
    framePath.stroke()

    let toolbarRect = NSRect(x: frameRect.minX, y: frameRect.maxY - size * 0.16, width: frameRect.width, height: size * 0.13)
    BrandPalette.night.withAlphaComponent(0.55).setFill()
    NSBezierPath(roundedRect: toolbarRect, xRadius: size * 0.08, yRadius: size * 0.08).fill()

    let dotColors = [BrandPalette.ember, NSColor.systemYellow, BrandPalette.sky]
    for (index, color) in dotColors.enumerated() {
        color.setFill()
        let dotSize = size * 0.05
        let x = toolbarRect.minX + size * 0.06 + CGFloat(index) * size * 0.07
        let y = toolbarRect.midY - dotSize / 2
        NSBezierPath(ovalIn: NSRect(x: x, y: y, width: dotSize, height: dotSize)).fill()
    }

    let shieldPath = NSBezierPath()
    shieldPath.move(to: NSPoint(x: size * 0.50, y: size * 0.68))
    shieldPath.curve(to: NSPoint(x: size * 0.70, y: size * 0.61),
                     controlPoint1: NSPoint(x: size * 0.58, y: size * 0.69),
                     controlPoint2: NSPoint(x: size * 0.67, y: size * 0.67))
    shieldPath.line(to: NSPoint(x: size * 0.70, y: size * 0.45))
    shieldPath.curve(to: NSPoint(x: size * 0.50, y: size * 0.28),
                     controlPoint1: NSPoint(x: size * 0.69, y: size * 0.36),
                     controlPoint2: NSPoint(x: size * 0.60, y: size * 0.30))
    shieldPath.curve(to: NSPoint(x: size * 0.30, y: size * 0.45),
                     controlPoint1: NSPoint(x: size * 0.40, y: size * 0.30),
                     controlPoint2: NSPoint(x: size * 0.31, y: size * 0.36))
    shieldPath.line(to: NSPoint(x: size * 0.30, y: size * 0.61))
    shieldPath.curve(to: NSPoint(x: size * 0.50, y: size * 0.68),
                     controlPoint1: NSPoint(x: size * 0.33, y: size * 0.67),
                     controlPoint2: NSPoint(x: size * 0.42, y: size * 0.69))
    shieldPath.close()

    let shieldGradient = NSGradient(colors: [BrandPalette.sky, BrandPalette.ocean, BrandPalette.ember])!
    shieldGradient.draw(in: shieldPath, angle: -65)

    let check = NSBezierPath()
    check.move(to: NSPoint(x: size * 0.41, y: size * 0.48))
    check.line(to: NSPoint(x: size * 0.48, y: size * 0.41))
    check.line(to: NSPoint(x: size * 0.60, y: size * 0.54))
    BrandPalette.frost.setStroke()
    check.lineWidth = max(4, size * 0.032)
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    check.stroke()

    let signalPath = NSBezierPath()
    signalPath.move(to: NSPoint(x: size * 0.22, y: size * 0.30))
    signalPath.curve(to: NSPoint(x: size * 0.78, y: size * 0.37),
                     controlPoint1: NSPoint(x: size * 0.33, y: size * 0.35),
                     controlPoint2: NSPoint(x: size * 0.61, y: size * 0.25))
    BrandPalette.ember.withAlphaComponent(0.95).setStroke()
    signalPath.lineWidth = max(4, size * 0.026)
    signalPath.lineCapStyle = .round
    signalPath.stroke()

    if includeWordmark {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size * 0.12, weight: .bold),
            .foregroundColor: BrandPalette.frost,
            .paragraphStyle: paragraph
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: size * 0.052, weight: .medium),
            .foregroundColor: BrandPalette.sky.withAlphaComponent(0.95),
            .paragraphStyle: paragraph
        ]

        NSString(string: "BestBrowser").draw(in: NSRect(x: size * 0.12, y: size * 0.10, width: size * 0.76, height: size * 0.12), withAttributes: titleAttributes)
        NSString(string: "Private signal. Clear intent.").draw(in: NSRect(x: size * 0.12, y: size * 0.04, width: size * 0.76, height: size * 0.06), withAttributes: subtitleAttributes)
    }
}

func renderArtwork(pixelSize: Int, insetScale: CGFloat = 0.1, includeWordmark: Bool = false) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "BrandAssets", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }

    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "BrandAssets", code: 2)
    }
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    drawBaseArtwork(
        in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
        insetScale: insetScale,
        includeWordmark: includeWordmark
    )

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "BrandAssets", code: 3)
    }
    return png
}

func savePNGData(_ data: Data, to url: URL) throws {
    try data.write(to: url)
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "BrandAssets", code: 4)
    }
    try png.write(to: url)
}

func resizePNG(at source: URL, pixels: Int, destination: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = ["-z", "\(pixels)", "\(pixels)", source.path, "--out", destination.path]
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "BrandAssets", code: 5)
    }
}

let iconDefinitions: [(name: String, pixels: Int)] = [
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

let temporaryRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)

let iconMasterURL = temporaryRoot.appendingPathComponent("icon-master.png")
let brandMasterURL = temporaryRoot.appendingPathComponent("brand-master.png")

try savePNGData(try renderArtwork(pixelSize: 2048), to: iconMasterURL)
try savePNGData(try renderArtwork(pixelSize: 2400, insetScale: 0.08, includeWordmark: true), to: brandMasterURL)

for icon in iconDefinitions {
    try resizePNG(at: iconMasterURL, pixels: icon.pixels, destination: iconSetURL.appendingPathComponent(icon.name))
}

try resizePNG(at: brandMasterURL, pixels: 1600, destination: brandMarkURL.appendingPathComponent("brandmark.png"))
try resizePNG(at: brandMasterURL, pixels: 1600, destination: exportedBrandingURL.appendingPathComponent("brandmark-hero.png"))
try resizePNG(at: iconMasterURL, pixels: 1024, destination: exportedBrandingURL.appendingPathComponent("app-icon-master.png"))
try resizePNG(at: iconMasterURL, pixels: 512, destination: exportedBrandingURL.appendingPathComponent("launch-badge.png"))
try? FileManager.default.removeItem(at: temporaryRoot)

let appIconContents = """
{
  "images" : [
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "codex", "version" : 1 }
}
"""

let brandContents = """
{
  "images" : [
    { "filename" : "brandmark.png", "idiom" : "universal", "scale" : "1x" }
  ],
  "info" : { "author" : "codex", "version" : 1 }
}
"""

try appIconContents.write(to: iconSetURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
try brandContents.write(to: brandMarkURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

print("Generated branding assets in \(assetsRoot.path)")
