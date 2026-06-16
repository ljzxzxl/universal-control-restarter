import Cocoa

func drawBaseIcon(in rect: NSRect) {
    let iconRect = rect.insetBy(dx: rect.width * 0.06, dy: rect.height * 0.06)
    let iconPath = NSBezierPath(
        roundedRect: iconRect,
        xRadius: rect.width * 0.21,
        yRadius: rect.height * 0.21
    )

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.33, green: 0.75, blue: 1.0, alpha: 1),
        NSColor(calibratedRed: 0.00, green: 0.45, blue: 0.92, alpha: 1)
    ])
    gradient?.draw(in: iconPath, angle: 90)

    NSColor.white.withAlphaComponent(0.22).setStroke()
    iconPath.lineWidth = max(1, rect.width * 0.012)
    iconPath.stroke()

    let content = rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.23)

    let divider = NSBezierPath()
    divider.lineWidth = rect.width * 0.045
    divider.lineCapStyle = .round
    divider.move(to: NSPoint(x: rect.midX, y: content.minY + rect.height * 0.04))
    divider.line(to: NSPoint(x: rect.midX, y: content.maxY - rect.height * 0.02))
    NSColor.white.withAlphaComponent(0.42).setStroke()
    divider.stroke()

    let dotRadius = rect.width * 0.026
    for index in 0..<4 {
        let x = content.minX + CGFloat(index) * rect.width * 0.105
        let y = rect.midY
        NSColor.white.withAlphaComponent(0.88).setFill()
        NSBezierPath(ovalIn: NSRect(x: x, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)).fill()
    }

    let pointer = NSBezierPath()
    pointer.move(to: NSPoint(x: rect.maxX - rect.width * 0.26, y: rect.maxY - rect.height * 0.28))
    pointer.line(to: NSPoint(x: rect.maxX - rect.width * 0.26, y: rect.minY + rect.height * 0.34))
    pointer.line(to: NSPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.45))
    pointer.close()
    NSColor.white.withAlphaComponent(0.93).setFill()
    pointer.fill()

    NSColor(calibratedRed: 0.62, green: 0.90, blue: 1.0, alpha: 0.55).setStroke()
    pointer.lineWidth = max(1, rect.width * 0.011)
    pointer.stroke()
}

func drawRestartBadge(in rect: NSRect, scale: CGFloat) {
    let badgeSize = max(10, rect.width * 0.38)
    let margin = max(2, rect.width * 0.055)
    let badgeRect = NSRect(
        x: rect.maxX - badgeSize - margin,
        y: rect.minY + margin,
        width: badgeSize,
        height: badgeSize
    )

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowOffset = NSSize(width: 0, height: -max(1, scale))
    shadow.shadowBlurRadius = max(1.5, badgeSize * 0.08)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.12, alpha: 1.0).setFill()
    NSBezierPath(ovalIn: badgeRect).fill()
    NSGraphicsContext.restoreGraphicsState()

    let symbolInset = badgeSize * 0.21
    let symbolRect = badgeRect.insetBy(dx: symbolInset, dy: symbolInset)
    let pointConfig = NSImage.SymbolConfiguration(pointSize: badgeSize * 0.54, weight: .bold)
    let colorConfig = NSImage.SymbolConfiguration(paletteColors: [.white])
    let symbolConfig = pointConfig.applying(colorConfig)
    if
        let configuredSymbol = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfig)
    {
        let symbol = configuredSymbol.copy() as? NSImage ?? configuredSymbol
        NSGraphicsContext.saveGraphicsState()
        symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        return
    }

    NSColor.white.setStroke()
    let lineWidth = max(1.5, badgeSize * 0.09)
    let center = NSPoint(x: badgeRect.midX, y: badgeRect.midY)
    let radius = badgeSize * 0.24
    let arc = NSBezierPath()
    arc.lineWidth = lineWidth
    arc.lineCapStyle = .round
    arc.appendArc(withCenter: center, radius: radius, startAngle: 35, endAngle: 315)
    arc.stroke()
}

func renderIcon(pixelSize: Int, outputPath: String) throws {
    let size = NSSize(width: pixelSize, height: pixelSize)
    let image = NSImage(size: size)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    let rect = NSRect(origin: .zero, size: size)
    drawBaseIcon(in: rect)
    drawRestartBadge(in: rect, scale: CGFloat(pixelSize) / 128.0)

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconBadge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render PNG"])
    }

    try png.write(to: URL(fileURLWithPath: outputPath))
}

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fputs("usage: GenerateIcon <output-iconset>\n", stderr)
    exit(64)
}

let iconsetPath = arguments[1]

try FileManager.default.createDirectory(
    atPath: iconsetPath,
    withIntermediateDirectories: true,
    attributes: nil
)

let icons: [(String, Int)] = [
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

for (name, size) in icons {
    try renderIcon(
        pixelSize: size,
        outputPath: URL(fileURLWithPath: iconsetPath).appendingPathComponent(name).path
    )
}
