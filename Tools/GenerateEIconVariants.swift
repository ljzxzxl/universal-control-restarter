import Cocoa

struct Variant {
    let id: String
    let title: String
    let draw: (NSRect) -> Void
}

func c(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
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
    NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
}

func drawIconBackground(in rect: NSRect, colors: [NSColor], angle: CGFloat = 90) {
    let iconRect = rect.insetBy(dx: rect.width * 0.055, dy: rect.height * 0.055)
    let path = rounded(iconRect, rect.width * 0.215)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowOffset = NSSize(width: 0, height: -rect.width * 0.018)
    shadow.shadowBlurRadius = rect.width * 0.04

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    (NSGradient(colors: colors) ?? NSGradient(starting: colors.first!, ending: colors.last!))?.draw(in: path, angle: angle)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.25).setStroke()
    path.lineWidth = max(1.5, rect.width * 0.012)
    path.stroke()

    let inset = rect.width * 0.035
    NSColor.white.withAlphaComponent(0.10).setStroke()
    let shine = rounded(iconRect.insetBy(dx: inset, dy: inset), rect.width * 0.175)
    shine.lineWidth = max(1, rect.width * 0.006)
    shine.stroke()
}

func drawSignalArcs(center: NSPoint, radii: [CGFloat], start: CGFloat, end: CGFloat, color: NSColor, width: CGFloat) {
    for (index, radius) in radii.enumerated() {
        let arc = NSBezierPath()
        arc.lineWidth = max(1.5, width - CGFloat(index) * width * 0.08)
        arc.lineCapStyle = .round
        arc.appendArc(withCenter: center, radius: radius, startAngle: start, endAngle: end)
        color.withAlphaComponent(max(0.22, color.alphaComponent - CGFloat(index) * 0.16)).setStroke()
        arc.stroke()
    }
}

func drawRefreshBadge(in rect: NSRect, color badgeColor: NSColor = c(0.08, 0.45, 0.92)) {
    let badgeSize = rect.width * 0.35
    let margin = rect.width * 0.064
    let badgeRect = NSRect(x: rect.maxX - badgeSize - margin, y: rect.minY + margin, width: badgeSize, height: badgeSize)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
    shadow.shadowOffset = NSSize(width: 0, height: -rect.width * 0.012)
    shadow.shadowBlurRadius = rect.width * 0.025

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    badgeColor.setFill()
    NSBezierPath(ovalIn: badgeRect).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.90).setStroke()
    let ring = NSBezierPath(ovalIn: badgeRect.insetBy(dx: badgeSize * 0.09, dy: badgeSize * 0.09))
    ring.lineWidth = max(1.4, badgeSize * 0.035)
    ring.stroke()

    let symbolRect = badgeRect.insetBy(dx: badgeSize * 0.21, dy: badgeSize * 0.21)
    let config = NSImage.SymbolConfiguration(pointSize: badgeSize * 0.54, weight: .bold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1)
    }
}

func drawMacBook(frame: NSRect, screenFill: NSColor = c(0.02, 0.04, 0.055, 0.90), glow: NSColor = .white.withAlphaComponent(0.0), alpha: CGFloat = 1) {
    let screenOuter = NSRect(x: frame.minX + frame.width * 0.05,
                             y: frame.minY + frame.height * 0.22,
                             width: frame.width * 0.90,
                             height: frame.height * 0.67)
    let radius = frame.width * 0.060

    if glow.alphaComponent > 0 {
        let shadow = NSShadow()
        shadow.shadowColor = glow.withAlphaComponent(0.45 * alpha)
        shadow.shadowOffset = .zero
        shadow.shadowBlurRadius = frame.width * 0.075
        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        NSColor.white.withAlphaComponent(0.001).setFill()
        rounded(screenOuter, radius).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    let aluminum = NSGradient(colors: [
        c(0.95, 0.96, 0.97, alpha),
        c(0.64, 0.70, 0.75, alpha)
    ])
    aluminum?.draw(in: rounded(screenOuter, radius), angle: 90)

    let screen = screenOuter.insetBy(dx: frame.width * 0.045, dy: frame.width * 0.045)
    screenFill.withAlphaComponent(screenFill.alphaComponent * alpha).setFill()
    rounded(screen, radius * 0.52).fill()

    c(0.18, 0.22, 0.25, 0.38 * alpha).setStroke()
    let screenStroke = rounded(screenOuter, radius)
    screenStroke.lineWidth = max(1.2, frame.width * 0.018)
    screenStroke.stroke()

    drawDisc(center: NSPoint(x: screen.midX, y: screen.maxY - screen.height * 0.07),
             radius: max(1.5, frame.width * 0.010),
             color: c(0.10, 0.13, 0.16, 0.72 * alpha))

    let base = NSBezierPath()
    base.move(to: NSPoint(x: frame.minX, y: frame.minY + frame.height * 0.16))
    base.line(to: NSPoint(x: frame.maxX, y: frame.minY + frame.height * 0.16))
    base.line(to: NSPoint(x: frame.maxX - frame.width * 0.07, y: frame.minY + frame.height * 0.06))
    base.line(to: NSPoint(x: frame.minX + frame.width * 0.07, y: frame.minY + frame.height * 0.06))
    base.close()
    aluminum?.draw(in: base, angle: -90)

    c(0.88, 0.91, 0.93, 0.60 * alpha).setFill()
    rounded(NSRect(x: frame.midX - frame.width * 0.10,
                   y: frame.minY + frame.height * 0.105,
                   width: frame.width * 0.20,
                   height: frame.height * 0.018),
            frame.height * 0.012).fill()
}

func drawIMac(frame: NSRect, screenFill: NSColor = c(0.02, 0.04, 0.055, 0.90), alpha: CGFloat = 1) {
    let display = NSRect(x: frame.minX, y: frame.minY + frame.height * 0.25, width: frame.width, height: frame.height * 0.62)
    let radius = frame.width * 0.055

    c(0.89, 0.92, 0.94, alpha).setFill()
    rounded(display, radius).fill()
    c(0.24, 0.29, 0.33, 0.24 * alpha).setStroke()
    let displayStroke = rounded(display, radius)
    displayStroke.lineWidth = max(1.4, frame.width * 0.020)
    displayStroke.stroke()

    let screen = display.insetBy(dx: frame.width * 0.050, dy: frame.width * 0.046)
    screenFill.withAlphaComponent(screenFill.alphaComponent * alpha).setFill()
    rounded(screen, radius * 0.46).fill()

    let chin = NSRect(x: display.minX + frame.width * 0.05, y: display.minY + frame.height * 0.035, width: frame.width * 0.90, height: frame.height * 0.08)
    c(0.84, 0.88, 0.91, 0.95 * alpha).setFill()
    rounded(chin, frame.width * 0.018).fill()
    drawDisc(center: NSPoint(x: chin.midX, y: chin.midY), radius: frame.width * 0.012, color: c(0.60, 0.66, 0.70, 0.72 * alpha))

    let standTop = NSPoint(x: frame.midX, y: display.minY)
    drawLine(from: standTop,
             to: NSPoint(x: frame.midX, y: frame.minY + frame.height * 0.12),
             width: frame.width * 0.055,
             color: c(0.79, 0.84, 0.87, 0.95 * alpha),
             cap: .butt)
    drawLine(from: NSPoint(x: frame.midX - frame.width * 0.17, y: frame.minY + frame.height * 0.11),
             to: NSPoint(x: frame.midX + frame.width * 0.17, y: frame.minY + frame.height * 0.11),
             width: frame.width * 0.044,
             color: c(0.86, 0.90, 0.92, 0.92 * alpha))
}

func drawDottedBridge(from start: NSPoint, to end: NSPoint, count: Int, radius: CGFloat, color: NSColor) {
    guard count > 1 else { return }
    for index in 0..<count {
        let t = CGFloat(index) / CGFloat(count - 1)
        let curve = sin(t * .pi)
        let point = NSPoint(x: start.x + (end.x - start.x) * t,
                            y: start.y + (end.y - start.y) * t + curve * radius * 3.4)
        drawDisc(center: point, radius: radius * (0.70 + curve * 0.40), color: color.withAlphaComponent(0.36 + curve * 0.48))
    }
}

func drawVariantE1(in rect: NSRect) {
    drawIconBackground(in: rect, colors: [
        c(0.10, 0.28, 0.36),
        c(0.28, 0.62, 0.77),
        c(0.95, 0.67, 0.24)
    ], angle: 82)

    let left = NSRect(x: rect.width * 0.14, y: rect.height * 0.25, width: rect.width * 0.31, height: rect.height * 0.35)
    let right = NSRect(x: rect.width * 0.55, y: rect.height * 0.29, width: rect.width * 0.31, height: rect.height * 0.35)
    drawMacBook(frame: left, glow: c(0.80, 0.97, 1.00))
    drawMacBook(frame: right, glow: c(0.80, 0.97, 1.00))

    let center = NSPoint(x: rect.midX, y: rect.height * 0.62)
    drawSignalArcs(center: center,
                   radii: [rect.width * 0.11, rect.width * 0.19, rect.width * 0.27],
                   start: 28,
                   end: 152,
                   color: c(1.0, 1.0, 1.0, 0.78),
                   width: rect.width * 0.020)
    drawDisc(center: center, radius: rect.width * 0.027, color: c(1.0, 0.68, 0.15))
    drawRefreshBadge(in: rect, color: c(0.08, 0.47, 0.93))
}

func drawVariantE2(in rect: NSRect) {
    drawIconBackground(in: rect, colors: [
        c(0.02, 0.16, 0.26),
        c(0.02, 0.55, 0.66),
        c(0.09, 0.78, 0.50)
    ], angle: 90)

    let left = NSRect(x: rect.width * 0.13, y: rect.height * 0.26, width: rect.width * 0.30, height: rect.height * 0.39)
    let right = NSRect(x: rect.width * 0.57, y: rect.height * 0.26, width: rect.width * 0.30, height: rect.height * 0.39)
    drawIMac(frame: left)
    drawIMac(frame: right)

    let bridge = NSBezierPath()
    bridge.move(to: NSPoint(x: left.maxX - rect.width * 0.010, y: rect.height * 0.52))
    bridge.curve(to: NSPoint(x: right.minX + rect.width * 0.010, y: rect.height * 0.52),
                 controlPoint1: NSPoint(x: rect.width * 0.42, y: rect.height * 0.71),
                 controlPoint2: NSPoint(x: rect.width * 0.58, y: rect.height * 0.71))
    bridge.lineWidth = rect.width * 0.034
    bridge.lineCapStyle = .round
    c(1.0, 1.0, 1.0, 0.80).setStroke()
    bridge.stroke()

    drawDottedBridge(from: NSPoint(x: left.maxX, y: rect.height * 0.46),
                     to: NSPoint(x: right.minX, y: rect.height * 0.46),
                     count: 5,
                     radius: rect.width * 0.017,
                     color: c(0.68, 1.0, 0.83))
    drawRefreshBadge(in: rect, color: c(0.98, 0.50, 0.13))
}

func drawVariantE3(in rect: NSRect) {
    drawIconBackground(in: rect, colors: [
        c(0.08, 0.10, 0.16),
        c(0.17, 0.41, 0.64),
        c(0.78, 0.38, 0.66)
    ], angle: 78)

    let left = NSRect(x: rect.width * 0.15, y: rect.height * 0.23, width: rect.width * 0.31, height: rect.height * 0.35)
    let right = NSRect(x: rect.width * 0.54, y: rect.height * 0.33, width: rect.width * 0.31, height: rect.height * 0.35)
    drawMacBook(frame: left, glow: c(0.72, 0.90, 1.0))
    drawMacBook(frame: right, glow: c(1.0, 0.78, 0.96))

    let channel = NSBezierPath()
    channel.move(to: NSPoint(x: left.maxX - rect.width * 0.030, y: rect.height * 0.47))
    channel.curve(to: NSPoint(x: right.minX + rect.width * 0.030, y: rect.height * 0.57),
                  controlPoint1: NSPoint(x: rect.width * 0.43, y: rect.height * 0.60),
                  controlPoint2: NSPoint(x: rect.width * 0.57, y: rect.height * 0.43))
    channel.lineWidth = rect.width * 0.090
    channel.lineCapStyle = .round
    c(0.25, 0.91, 1.0, 0.18).setStroke()
    channel.stroke()
    channel.lineWidth = rect.width * 0.032
    c(0.86, 1.0, 1.0, 0.80).setStroke()
    channel.stroke()

    for index in 0..<4 {
        let x = rect.width * (0.39 + CGFloat(index) * 0.075)
        drawDisc(center: NSPoint(x: x, y: rect.height * (0.56 - CGFloat(index % 2) * 0.045)),
                 radius: rect.width * 0.020,
                 color: c(1.0, 1.0, 1.0, 0.65))
    }

    drawRefreshBadge(in: rect, color: c(0.16, 0.74, 0.50))
}

func drawVariantE4(in rect: NSRect) {
    drawIconBackground(in: rect, colors: [
        c(0.04, 0.22, 0.31),
        c(0.12, 0.50, 0.62),
        c(0.88, 0.78, 0.46)
    ], angle: 90)

    let left = NSRect(x: rect.width * 0.13, y: rect.height * 0.23, width: rect.width * 0.32, height: rect.height * 0.37)
    let right = NSRect(x: rect.width * 0.55, y: rect.height * 0.23, width: rect.width * 0.32, height: rect.height * 0.37)
    drawMacBook(frame: left, screenFill: c(0.02, 0.06, 0.08, 0.88), glow: c(0.90, 1.0, 0.84))
    drawMacBook(frame: right, screenFill: c(0.02, 0.06, 0.08, 0.88), glow: c(0.90, 1.0, 0.84))

    let center = NSPoint(x: rect.midX, y: rect.height * 0.58)
    for index in 0..<3 {
        let ring = NSBezierPath(ovalIn: NSRect(x: center.x - rect.width * (0.065 + CGFloat(index) * 0.072),
                                               y: center.y - rect.width * (0.065 + CGFloat(index) * 0.072),
                                               width: rect.width * (0.13 + CGFloat(index) * 0.144),
                                               height: rect.width * (0.13 + CGFloat(index) * 0.144)))
        ring.lineWidth = rect.width * 0.014
        c(1.0, 1.0, 1.0, 0.70 - CGFloat(index) * 0.14).setStroke()
        ring.stroke()
    }
    drawDisc(center: center, radius: rect.width * 0.028, color: c(0.24, 0.92, 0.72))

    drawLine(from: NSPoint(x: left.maxX - rect.width * 0.015, y: rect.height * 0.47),
             to: NSPoint(x: center.x - rect.width * 0.032, y: center.y),
             width: rect.width * 0.019,
             color: c(1.0, 1.0, 1.0, 0.62))
    drawLine(from: NSPoint(x: center.x + rect.width * 0.032, y: center.y),
             to: NSPoint(x: right.minX + rect.width * 0.015, y: rect.height * 0.47),
             width: rect.width * 0.019,
             color: c(1.0, 1.0, 1.0, 0.62))
    drawRefreshBadge(in: rect, color: c(0.08, 0.45, 0.92))
}

func drawVariantE5(in rect: NSRect) {
    drawIconBackground(in: rect, colors: [
        c(0.88, 0.95, 0.98),
        c(0.15, 0.64, 0.86),
        c(0.04, 0.30, 0.46)
    ], angle: 92)

    let left = NSRect(x: rect.width * 0.12, y: rect.height * 0.25, width: rect.width * 0.32, height: rect.height * 0.37)
    let right = NSRect(x: rect.width * 0.56, y: rect.height * 0.31, width: rect.width * 0.31, height: rect.height * 0.36)
    drawIMac(frame: left, screenFill: c(0.02, 0.07, 0.10, 0.78))
    drawMacBook(frame: right, screenFill: c(0.02, 0.06, 0.09, 0.82), glow: c(0.73, 0.96, 1.0))

    let upper = NSBezierPath()
    upper.move(to: NSPoint(x: rect.width * 0.33, y: rect.height * 0.62))
    upper.curve(to: NSPoint(x: rect.width * 0.66, y: rect.height * 0.68),
                controlPoint1: NSPoint(x: rect.width * 0.42, y: rect.height * 0.78),
                controlPoint2: NSPoint(x: rect.width * 0.57, y: rect.height * 0.78))
    upper.lineWidth = rect.width * 0.030
    upper.lineCapStyle = .round
    c(1.0, 1.0, 1.0, 0.76).setStroke()
    upper.stroke()

    let lower = NSBezierPath()
    lower.move(to: NSPoint(x: rect.width * 0.67, y: rect.height * 0.52))
    lower.curve(to: NSPoint(x: rect.width * 0.34, y: rect.height * 0.47),
                controlPoint1: NSPoint(x: rect.width * 0.57, y: rect.height * 0.38),
                controlPoint2: NSPoint(x: rect.width * 0.43, y: rect.height * 0.38))
    lower.lineWidth = rect.width * 0.022
    lower.lineCapStyle = .round
    c(0.74, 1.0, 0.92, 0.64).setStroke()
    lower.stroke()

    drawDisc(center: NSPoint(x: rect.width * 0.50, y: rect.height * 0.64), radius: rect.width * 0.020, color: c(1.0, 0.71, 0.20))
    drawDisc(center: NSPoint(x: rect.width * 0.51, y: rect.height * 0.45), radius: rect.width * 0.015, color: c(0.80, 1.0, 0.88))
    drawRefreshBadge(in: rect, color: c(0.98, 0.47, 0.12))
}

func saveImage(size: Int, to url: URL, draw: (NSRect) -> Void) throws {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    draw(NSRect(x: 0, y: 0, width: size, height: size))
    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "EIconVariants", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render PNG"])
    }

    try png.write(to: url)
}

func saveContactSheet(variants: [Variant], outputDirectory: URL) throws {
    let tileSize: CGFloat = 320
    let margin: CGFloat = 52
    let labelHeight: CGFloat = 64
    let width = margin + CGFloat(variants.count) * (tileSize + margin)
    let height = margin * 2 + tileSize + labelHeight
    let image = NSImage(size: NSSize(width: width, height: height))

    image.lockFocus()
    c(0.95, 0.96, 0.97).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    for (index, variant) in variants.enumerated() {
        let x = margin + CGFloat(index) * (tileSize + margin)
        let y = margin + labelHeight
        if let icon = NSImage(contentsOf: outputDirectory.appendingPathComponent("\(variant.id).png")) {
            icon.draw(in: NSRect(x: x, y: y, width: tileSize, height: tileSize),
                      from: .zero,
                      operation: .sourceOver,
                      fraction: 1)
        }

        let label = "\(variant.id.uppercased())  \(variant.title)"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 21, weight: .semibold),
            .foregroundColor: c(0.14, 0.16, 0.19),
            .paragraphStyle: paragraph
        ]
        label.draw(in: NSRect(x: x - 12, y: margin * 0.62, width: tileSize + 24, height: 42), withAttributes: attrs)
    }

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "EIconVariants", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not render contact sheet"])
    }

    try png.write(to: outputDirectory.appendingPathComponent("contact-sheet.png"))
}

func saveDockPreview(variants: [Variant], outputDirectory: URL) throws {
    let margin: CGFloat = 42
    let rowGap: CGFloat = 34
    let labelWidth: CGFloat = 170
    let sizes: [CGFloat] = [256, 128, 64]
    let tileWidth = sizes.reduce(CGFloat(0), +) + CGFloat(sizes.count - 1) * rowGap
    let width = margin * 2 + labelWidth + tileWidth
    let rowHeight: CGFloat = 292
    let height = margin * 2 + CGFloat(variants.count) * rowHeight
    let image = NSImage(size: NSSize(width: width, height: height))

    image.lockFocus()
    c(0.95, 0.96, 0.97).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    for (index, variant) in variants.enumerated() {
        let y = height - margin - CGFloat(index + 1) * rowHeight + 18
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: c(0.14, 0.16, 0.19),
            .paragraphStyle: paragraph
        ]
        variant.id.uppercased().draw(in: NSRect(x: margin, y: y + 106, width: labelWidth, height: 36), withAttributes: attrs)

        var x = margin + labelWidth
        if let icon = NSImage(contentsOf: outputDirectory.appendingPathComponent("\(variant.id).png")) {
            for size in sizes {
                icon.draw(in: NSRect(x: x, y: y + (256 - size) / 2, width: size, height: size),
                          from: .zero,
                          operation: .sourceOver,
                          fraction: 1)
                x += size + rowGap
            }
        }
    }

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "EIconVariants", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not render dock preview"])
    }

    try png.write(to: outputDirectory.appendingPathComponent("dock-preview.png"))
}

let variants = [
    Variant(id: "e1-maclink", title: "Mac Link", draw: drawVariantE1),
    Variant(id: "e2-desktops", title: "Desktop Bridge", draw: drawVariantE2),
    Variant(id: "e3-airbridge", title: "Air Bridge", draw: drawVariantE3),
    Variant(id: "e4-nearby", title: "Nearby Field", draw: drawVariantE4),
    Variant(id: "e5-handoff", title: "Handoff Path", draw: drawVariantE5)
]

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Resources/icon-candidates/e-variants", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for variant in variants {
    try saveImage(size: 1024, to: outputDirectory.appendingPathComponent("\(variant.id).png"), draw: variant.draw)
}

try saveContactSheet(variants: variants, outputDirectory: outputDirectory)
try saveDockPreview(variants: variants, outputDirectory: outputDirectory)
print("Generated \(variants.count) E icon variants in \(outputDirectory.path)")
