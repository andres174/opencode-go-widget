#!/usr/bin/env swift
import AppKit
import Foundation

let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let resourcesDir = repoRoot.appendingPathComponent("Resources")
let iconsetDir = resourcesDir.appendingPathComponent("AppIcon.iconset")

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.2237

    let background = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.16, green: 0.58, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.07, green: 0.28, blue: 0.72, alpha: 1),
    ])!.draw(in: background, angle: -90)

    let barWidth = size * 0.13
    let gap = size * 0.075
    let totalWidth = barWidth * 3 + gap * 2
    let startX = (size - totalWidth) / 2
    let bottom = size * 0.24
    let maxBarHeight = size - bottom * 2
    let heights: [CGFloat] = [0.45, 0.7, 1.0]

    NSColor.white.setFill()
    for (index, heightFactor) in heights.enumerated() {
        let barHeight = maxBarHeight * heightFactor
        let x = startX + CGFloat(index) * (barWidth + gap)
        let bar = NSBezierPath(
            roundedRect: NSRect(x: x, y: bottom, width: barWidth, height: barHeight),
            xRadius: barWidth * 0.18,
            yRadius: barWidth * 0.18
        )
        bar.fill()
    }
    return image
}

func writePNG(image: NSImage, pixels: Int, to url: URL) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { fatalError("Could not create bitmap rep") }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG")
    }
    try! data.write(to: url)
}

try? FileManager.default.removeItem(at: iconsetDir)
try! FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
try! FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

for baseSize in [16, 32, 128, 256, 512] {
    let baseImage = drawIcon(size: CGFloat(baseSize))
    writePNG(image: baseImage, pixels: baseSize, to: iconsetDir.appendingPathComponent("icon_\(baseSize)x\(baseSize).png"))

    let retinaSize = baseSize * 2
    let retinaImage = drawIcon(size: CGFloat(retinaSize))
    writePNG(image: retinaImage, pixels: retinaSize, to: iconsetDir.appendingPathComponent("icon_\(baseSize)x\(baseSize)@2x.png"))
}

let icnsURL = resourcesDir.appendingPathComponent("AppIcon.icns")
try? FileManager.default.removeItem(at: icnsURL)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsURL.path]
process.standardOutput = FileHandle.standardOutput
process.standardError = FileHandle.standardError
try! process.run()
process.waitUntilExit()

try? FileManager.default.removeItem(at: iconsetDir)

print("Created: \(icnsURL.path)")
