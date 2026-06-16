import Cocoa

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawLine(from start: NSPoint, to end: NSPoint, width: CGFloat, color: NSColor, cap: NSBezierPath.LineCapStyle = .round) {
    let line = NSBezierPath()
    line.move(to: start)
    line.line(to: end)
    line.lineWidth = width
    line.lineCapStyle = cap
    color.setStroke()
    line.stroke()
}

func drawDisc(center: NSPoint, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(
        ovalIn: NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
    ).fill()
}

func drawBackground(in rect: NSRect) {
    let iconRect = rect.insetBy(dx: rect.width * 0.055, dy: rect.height * 0.055)
    let background = roundedRect(iconRect, radius: rect.width * 0.215)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowOffset = NSSize(width: 0, height: -rect.width * 0.018)
    shadow.shadowBlurRadius = rect.width * 0.04

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSGradient(colors: [
        color(0.04, 0.22, 0.31),
        color(0.12, 0.50, 0.62),
        color(0.88, 0.78, 0.46)
    ])?.draw(in: background, angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.25).setStroke()
    background.lineWidth = max(1.5, rect.width * 0.012)
    background.stroke()

    let shine = roundedRect(
        iconRect.insetBy(dx: rect.width * 0.035, dy: rect.height * 0.035),
        radius: rect.width * 0.175
    )
    NSColor.white.withAlphaComponent(0.10).setStroke()
    shine.lineWidth = max(1, rect.width * 0.006)
    shine.stroke()
}

func drawMacBook(frame: NSRect, screenFill: NSColor, glow: NSColor) {
    let screenOuter = NSRect(
        x: frame.minX + frame.width * 0.05,
        y: frame.minY + frame.height * 0.22,
        width: frame.width * 0.90,
        height: frame.height * 0.67
    )
    let radius = frame.width * 0.060

    let glowShadow = NSShadow()
    glowShadow.shadowColor = glow.withAlphaComponent(0.45)
    glowShadow.shadowOffset = .zero
    glowShadow.shadowBlurRadius = frame.width * 0.075

    NSGraphicsContext.saveGraphicsState()
    glowShadow.set()
    NSColor.white.withAlphaComponent(0.001).setFill()
    roundedRect(screenOuter, radius: radius).fill()
    NSGraphicsContext.restoreGraphicsState()

    let aluminum = NSGradient(colors: [
        color(0.95, 0.96, 0.97),
        color(0.64, 0.70, 0.75)
    ])
    aluminum?.draw(in: roundedRect(screenOuter, radius: radius), angle: 90)

    let screen = screenOuter.insetBy(dx: frame.width * 0.045, dy: frame.width * 0.045)
    screenFill.setFill()
    roundedRect(screen, radius: radius * 0.52).fill()

    let screenStroke = roundedRect(screenOuter, radius: radius)
    color(0.18, 0.22, 0.25, 0.38).setStroke()
    screenStroke.lineWidth = max(1.2, frame.width * 0.018)
    screenStroke.stroke()

    drawDisc(
        center: NSPoint(x: screen.midX, y: screen.maxY - screen.height * 0.07),
        radius: max(1.5, frame.width * 0.010),
        color: color(0.10, 0.13, 0.16, 0.72)
    )

    let base = NSBezierPath()
    base.move(to: NSPoint(x: frame.minX, y: frame.minY + frame.height * 0.16))
    base.line(to: NSPoint(x: frame.maxX, y: frame.minY + frame.height * 0.16))
    base.line(to: NSPoint(x: frame.maxX - frame.width * 0.07, y: frame.minY + frame.height * 0.06))
    base.line(to: NSPoint(x: frame.minX + frame.width * 0.07, y: frame.minY + frame.height * 0.06))
    base.close()
    aluminum?.draw(in: base, angle: -90)

    color(0.88, 0.91, 0.93, 0.60).setFill()
    roundedRect(
        NSRect(
            x: frame.midX - frame.width * 0.10,
            y: frame.minY + frame.height * 0.105,
            width: frame.width * 0.20,
            height: frame.height * 0.018
        ),
        radius: frame.height * 0.012
    ).fill()
}

func drawNearbySignal(in rect: NSRect, from left: NSRect, to right: NSRect) {
    let center = NSPoint(x: rect.midX, y: rect.height * 0.58)

    for index in 0..<3 {
        let radius = rect.width * (0.065 + CGFloat(index) * 0.072)
        let ringRect = NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let ring = NSBezierPath(ovalIn: ringRect)
        ring.lineWidth = rect.width * 0.014
        color(1.0, 1.0, 1.0, 0.70 - CGFloat(index) * 0.14).setStroke()
        ring.stroke()
    }

    drawDisc(center: center, radius: rect.width * 0.028, color: color(0.24, 0.92, 0.72))

    drawLine(
        from: NSPoint(x: left.maxX - rect.width * 0.015, y: rect.height * 0.47),
        to: NSPoint(x: center.x - rect.width * 0.032, y: center.y),
        width: rect.width * 0.019,
        color: color(1.0, 1.0, 1.0, 0.62)
    )
    drawLine(
        from: NSPoint(x: center.x + rect.width * 0.032, y: center.y),
        to: NSPoint(x: right.minX + rect.width * 0.015, y: rect.height * 0.47),
        width: rect.width * 0.019,
        color: color(1.0, 1.0, 1.0, 0.62)
    )
}

func drawRestartBadge(in rect: NSRect) {
    let badgeSize = max(10, rect.width * 0.35)
    let margin = max(2, rect.width * 0.064)
    let badgeRect = NSRect(
        x: rect.maxX - badgeSize - margin,
        y: rect.minY + margin,
        width: badgeSize,
        height: badgeSize
    )

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
    shadow.shadowOffset = NSSize(width: 0, height: -rect.width * 0.012)
    shadow.shadowBlurRadius = rect.width * 0.025

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    color(0.08, 0.45, 0.92).setFill()
    NSBezierPath(ovalIn: badgeRect).fill()
    NSGraphicsContext.restoreGraphicsState()

    let ring = NSBezierPath(ovalIn: badgeRect.insetBy(dx: badgeSize * 0.09, dy: badgeSize * 0.09))
    NSColor.white.withAlphaComponent(0.90).setStroke()
    ring.lineWidth = max(1.4, badgeSize * 0.035)
    ring.stroke()

    let symbolRect = badgeRect.insetBy(dx: badgeSize * 0.21, dy: badgeSize * 0.21)
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: badgeSize * 0.54, weight: .bold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))

    if let symbol = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1)
        return
    }

    let center = NSPoint(x: badgeRect.midX, y: badgeRect.midY)
    let arc = NSBezierPath()
    arc.lineWidth = max(1.5, badgeSize * 0.09)
    arc.lineCapStyle = .round
    arc.appendArc(withCenter: center, radius: badgeSize * 0.24, startAngle: 35, endAngle: 315)
    NSColor.white.setStroke()
    arc.stroke()
}

func drawIcon(in rect: NSRect) {
    drawBackground(in: rect)

    let left = NSRect(
        x: rect.width * 0.13,
        y: rect.height * 0.23,
        width: rect.width * 0.32,
        height: rect.height * 0.37
    )
    let right = NSRect(
        x: rect.width * 0.55,
        y: rect.height * 0.23,
        width: rect.width * 0.32,
        height: rect.height * 0.37
    )

    let screenFill = color(0.02, 0.06, 0.08, 0.88)
    let glow = color(0.90, 1.0, 0.84)
    drawMacBook(frame: left, screenFill: screenFill, glow: glow)
    drawMacBook(frame: right, screenFill: screenFill, glow: glow)
    drawNearbySignal(in: rect, from: left, to: right)
    drawRestartBadge(in: rect)
}

func renderIcon(pixelSize: Int, outputPath: String) throws {
    let size = NSSize(width: pixelSize, height: pixelSize)
    let image = NSImage(size: size)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    drawIcon(in: NSRect(origin: .zero, size: size))

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "GenerateIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render PNG"])
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
