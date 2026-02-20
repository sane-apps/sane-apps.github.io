#!/usr/bin/env swift
import Cocoa
import CoreGraphics
import CoreText

let width = 1200
let height = 630
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path

// Create context
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// Flip coordinate system for easier positioning (origin top-left)
ctx.translateBy(x: 0, y: CGFloat(height))
ctx.scaleBy(x: 1, y: -1)

// Background gradient - dark theme matching website
let bgColor = CGColor(red: 0.031, green: 0.031, blue: 0.047, alpha: 1.0) // #08080c
ctx.setFillColor(bgColor)
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

// Subtle gradient overlay for depth
let gradientColors = [
    CGColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 0.3),
    CGColor(red: 0.031, green: 0.031, blue: 0.047, alpha: 0.0)
] as CFArray
if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(
        gradient,
        startCenter: CGPoint(x: 600, y: 250),
        startRadius: 0,
        endCenter: CGPoint(x: 600, y: 250),
        endRadius: 500,
        options: []
    )
}

// Accent glow behind logo
let glowColors = [
    CGColor(red: 0.373, green: 0.659, blue: 0.827, alpha: 0.15), // #5fa8d3
    CGColor(red: 0.373, green: 0.659, blue: 0.827, alpha: 0.0)
] as CFArray
if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: 600, y: 200),
        startRadius: 0,
        endCenter: CGPoint(x: 600, y: 200),
        endRadius: 350,
        options: []
    )
}

// Helper to draw images correctly in flipped context
func drawImage(from path: String, in rect: CGRect, circular: Bool = false) {
    guard let nsImage = NSImage(contentsOfFile: path) else { return }

    ctx.saveGState()
    if circular {
        ctx.addEllipse(in: rect)
        ctx.clip()
    } else {
        let cornerRadius: CGFloat = 12
        let clipPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(clipPath)
        ctx.clip()
    }

    // Un-flip for image drawing, then draw with NSImage which handles orientation
    ctx.translateBy(x: rect.origin.x, y: rect.origin.y + rect.height)
    ctx.scaleBy(x: 1, y: -1)
    let localRect = CGRect(origin: .zero, size: rect.size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    nsImage.draw(in: localRect)
    NSGraphicsContext.restoreGraphicsState()

    ctx.restoreGState()
}

// Load and draw logo
let logoPath = "\(scriptDir)/logo.png"
let logoSize: CGFloat = 140
let logoX = (CGFloat(width) - logoSize) / 2
let logoY: CGFloat = 100
let logoRect = CGRect(x: logoX, y: logoY, width: logoSize, height: logoSize)

drawImage(from: logoPath, in: logoRect, circular: true)

// Subtle ring around logo
ctx.setStrokeColor(CGColor(red: 0.373, green: 0.659, blue: 0.827, alpha: 0.4))
ctx.setLineWidth(2)
ctx.addEllipse(in: logoRect.insetBy(dx: -1, dy: -1))
ctx.strokePath()

// Draw title "SaneApps"
func drawCenteredText(_ text: String, y: CGFloat, fontSize: CGFloat, color: CGColor, weight: NSFont.Weight = .semibold) {
    let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: color) ?? NSColor.white
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let bounds = CTLineGetBoundsWithOptions(line, [])
    let x = (CGFloat(width) - bounds.width) / 2

    ctx.saveGState()
    // Need to flip back for text drawing
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1, y: -1)
    ctx.textPosition = CGPoint(x: x, y: CGFloat(height) - y - fontSize)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

let titleColor = CGColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0) // #f5f5f8
drawCenteredText("SaneApps", y: 265, fontSize: 52, color: titleColor, weight: .bold)

// Tagline
let taglineColor = CGColor(red: 0.373, green: 0.659, blue: 0.827, alpha: 1.0) // #5fa8d3
drawCenteredText("100% Transparent Code macOS Utilities", y: 330, fontSize: 24, color: taglineColor, weight: .medium)

// Subtitle
let subtitleColor = CGColor(red: 0.75, green: 0.75, blue: 0.82, alpha: 1.0) // muted
drawCenteredText("Privacy-First  \u{00B7}  No Telemetry  \u{00B7}  Native Swift", y: 370, fontSize: 18, color: subtitleColor, weight: .regular)

// Draw app icons in a row
let iconNames = ["sanebar-icon.png", "saneclip-icon.png", "sanehosts-icon.png", "sanesync-icon.png", "sanevideo-icon.png", "saneclick-icon.png"]
let iconSize: CGFloat = 56
let iconSpacing: CGFloat = 20
let totalWidth = CGFloat(iconNames.count) * iconSize + CGFloat(iconNames.count - 1) * iconSpacing
let startX = (CGFloat(width) - totalWidth) / 2
let iconY: CGFloat = 430

for (i, iconName) in iconNames.enumerated() {
    let iconPath = "\(scriptDir)/icons/\(iconName)"
    let x = startX + CGFloat(i) * (iconSize + iconSpacing)
    let rect = CGRect(x: x, y: iconY, width: iconSize, height: iconSize)
    drawImage(from: iconPath, in: rect, circular: false)
}

// Bottom accent line
ctx.setFillColor(CGColor(red: 0.373, green: 0.659, blue: 0.827, alpha: 0.6))
ctx.fill(CGRect(x: 400, y: 520, width: 400, height: 2))

// Bottom text
drawCenteredText("$6.99 Once, Yours Forever", y: 545, fontSize: 16, color: subtitleColor, weight: .medium)

// Bottom border accent
ctx.setFillColor(CGColor(red: 0.373, green: 0.659, blue: 0.827, alpha: 0.8))
ctx.fill(CGRect(x: 0, y: CGFloat(height) - 3, width: CGFloat(width), height: 3))

// Save
guard let image = ctx.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let outputPath = "\(scriptDir)/og-image.png"
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    print("Failed to create destination")
    exit(1)
}

CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("OG image saved to \(outputPath)")
