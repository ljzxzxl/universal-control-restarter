import Cocoa

struct IconCandidate {
    let id: String
    let title: String
    let draw: (NSRect) -> Void
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func path(_ block: (NSBezierPath) -> Void) -> NSBezierPath {
    let path = NSBezierPath()
    block(path)
    return path
}

func line(from start: NSPoint, to end: NSPoint, width: CGFloat, color: NSColor, cap: NSBezierPath.LineCapStyle = .round) {
    let stroke = NSBezierPath()
    stroke.move(to: start)
    stroke.line(to: end)
    stroke.lineWidth = width
    stroke.lineCapStyle = cap
    color.setStroke()
    stroke.stroke()
}

func drawBackground(in rect: NSRect, colors: [NSColor], radius: CGFloat? = nil) {
    let inset = rect.width * 0.055
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let corner = radius ?? rect.width * 0.215
    let background = NSBezierPath(roundedRect: iconRect, xRadius: corner, yRadius: corner)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowOffset = NSSize(width: 0, height: -rect.width * 0.018)
    shadow.shadowBlurRadius = rect.width * 0.04

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    (NSGradient(colors: colors) ?? NSGradient(starting: colors.first!, ending: colors.last!))?.draw(in: background, angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.24).setStroke()
    background.lineWidth = max(1.5, rect.width * 0.012)
    background.stroke()

    let shine = NSBezierPath(roundedRect: iconRect.insetBy(dx: rect.width * 0.035, dy: rect.width * 0.035),
                             xRadius: corner * 0.82,
                             yRadius: corner * 0.82)
    NSColor.white.withAlphaComponent(0.10).setStroke()
    shine.lineWidth = max(1, rect.width * 0.006)
    shine.stroke()
}

func drawMonitor(_ monitorRect: NSRect, fill: NSColor, stroke: NSColor, lineWidth: CGFloat, base: Bool = true) {
    let screen = NSBezierPath(roundedRect: monitorRect, xRadius: monitorRect.width * 0.08, yRadius: monitorRect.width * 0.08)
    fill.setFill()
    screen.fill()
    stroke.setStroke()
    screen.lineWidth = lineWidth
    screen.stroke()

    if base {
        let standWidth = monitorRect.width * 0.18
        line(from: NSPoint(x: monitorRect.midX, y: monitorRect.minY - monitorRect.height * 0.03),
             to: NSPoint(x: monitorRect.midX, y: monitorRect.minY - monitorRect.height * 0.13),
             width: lineWidth * 0.85,
             color: stroke.withAlphaComponent(0.82))
        line(from: NSPoint(x: monitorRect.midX - standWidth, y: monitorRect.minY - monitorRect.height * 0.14),
             to: NSPoint(x: monitorRect.midX + standWidth, y: monitorRect.minY - monitorRect.height * 0.14),
             width: lineWidth * 0.85,
             color: stroke.withAlphaComponent(0.82))
    }
}

func drawCursor(in rect: NSRect, fill: NSColor = .white, stroke: NSColor = NSColor.black.withAlphaComponent(0.16)) {
    let pointer = NSBezierPath()
    pointer.move(to: NSPoint(x: rect.minX, y: rect.maxY))
    pointer.line(to: NSPoint(x: rect.minX, y: rect.minY))
    pointer.line(to: NSPoint(x: rect.maxX * 0.985 + rect.minX * 0.015, y: rect.minY + rect.height * 0.38))
    pointer.line(to: NSPoint(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.51))
    pointer.close()
    fill.setFill()
    pointer.fill()
    stroke.setStroke()
    pointer.lineWidth = max(1.5, rect.width * 0.045)
    pointer.stroke()
}

func drawBadge(in rect: NSRect, color badgeColor: NSColor = color(1.0, 0.47, 0.10), symbol: String = "arrow.clockwise") {
    let badgeSize = rect.width * 0.36
    let margin = rect.width * 0.065
    let badgeRect = NSRect(x: rect.maxX - badgeSize - margin,
                           y: rect.minY + margin,
                           width: badgeSize,
                           height: badgeSize)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
    shadow.shadowOffset = NSSize(width: 0, height: -rect.width * 0.012)
    shadow.shadowBlurRadius = rect.width * 0.025

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    badgeColor.setFill()
    NSBezierPath(ovalIn: badgeRect).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.92).setStroke()
    let ring = NSBezierPath(ovalIn: badgeRect.insetBy(dx: badgeSize * 0.09, dy: badgeSize * 0.09))
    ring.lineWidth = max(1.4, badgeSize * 0.035)
    ring.stroke()

    let symbolRect = badgeRect.insetBy(dx: badgeSize * 0.21, dy: badgeSize * 0.21)
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: badgeSize * 0.54, weight: .bold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
        image.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1)
    } else {
        let center = NSPoint(x: badgeRect.midX, y: badgeRect.midY)
        let arrow = NSBezierPath()
        arrow.lineWidth = badgeSize * 0.085
        arrow.lineCapStyle = .round
        arrow.appendArc(withCenter: center, radius: badgeSize * 0.24, startAngle: 35, endAngle: 315)
        NSColor.white.setStroke()
        arrow.stroke()
    }
}

func drawSmallArrow(at center: NSPoint, angle degrees: CGFloat, size: CGFloat, color: NSColor) {
    let radians = degrees * .pi / 180
    let tip = center
    let back = NSPoint(x: center.x - cos(radians) * size, y: center.y - sin(radians) * size)
    let normal = NSPoint(x: -sin(radians), y: cos(radians))
    let arrow = NSBezierPath()
    arrow.move(to: tip)
    arrow.line(to: NSPoint(x: back.x + normal.x * size * 0.42, y: back.y + normal.y * size * 0.42))
    arrow.line(to: NSPoint(x: back.x - normal.x * size * 0.42, y: back.y - normal.y * size * 0.42))
    arrow.close()
    color.setFill()
    arrow.fill()
}

func drawDottedConnection(from start: NSPoint, to end: NSPoint, dots: Int, radius: CGFloat, color: NSColor) {
    guard dots > 1 else { return }
    for index in 0..<dots {
        let t = CGFloat(index) / CGFloat(dots - 1)
        let x = start.x + (end.x - start.x) * t
        let y = start.y + (end.y - start.y) * t + sin(t * .pi) * radius * 1.5
        let dotRadius = radius * (0.82 + 0.18 * sin(t * .pi))
        color.withAlphaComponent(0.45 + 0.42 * sin(t * .pi)).setFill()
        NSBezierPath(ovalIn: NSRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)).fill()
    }
}

func drawCandidateA(in rect: NSRect) {
    drawBackground(in: rect, colors: [
        color(0.02, 0.61, 0.92),
        color(0.08, 0.83, 0.68),
        color(0.02, 0.35, 0.88)
    ])

    let left = NSRect(x: rect.width * 0.17, y: rect.height * 0.42, width: rect.width * 0.31, height: rect.height * 0.22)
    let right = NSRect(x: rect.width * 0.52, y: rect.height * 0.35, width: rect.width * 0.34, height: rect.height * 0.27)
    drawMonitor(left, fill: color(0.00, 0.18, 0.35, 0.42), stroke: .white.withAlphaComponent(0.92), lineWidth: rect.width * 0.026)
    drawMonitor(right, fill: color(0.00, 0.21, 0.38, 0.43), stroke: .white.withAlphaComponent(0.96), lineWidth: rect.width * 0.026)

    drawDottedConnection(from: NSPoint(x: left.maxX + rect.width * 0.045, y: left.midY),
                         to: NSPoint(x: right.minX - rect.width * 0.04, y: right.midY + rect.height * 0.02),
                         dots: 5,
                         radius: rect.width * 0.018,
                         color: .white)

    drawCursor(in: NSRect(x: rect.width * 0.61, y: rect.height * 0.45, width: rect.width * 0.15, height: rect.height * 0.23),
               fill: .white.withAlphaComponent(0.96),
               stroke: color(0.00, 0.34, 0.55, 0.28))
    drawBadge(in: rect, color: color(1.0, 0.48, 0.10))
}

func drawCandidateB(in rect: NSRect) {
    drawBackground(in: rect, colors: [
        color(0.10, 0.14, 0.23),
        color(0.10, 0.52, 0.78),
        color(0.78, 0.25, 0.55)
    ])

    let center = NSPoint(x: rect.midX, y: rect.midY + rect.height * 0.015)
    let radius = rect.width * 0.27
    let outer = NSBezierPath()
    outer.lineWidth = rect.width * 0.035
    outer.lineCapStyle = .round
    outer.appendArc(withCenter: center, radius: radius, startAngle: 34, endAngle: 218)
    NSColor.white.withAlphaComponent(0.88).setStroke()
    outer.stroke()
    drawSmallArrow(at: NSPoint(x: center.x - radius * 0.77, y: center.y - radius * 0.64),
                   angle: 218,
                   size: rect.width * 0.045,
                   color: .white.withAlphaComponent(0.88))

    let inner = NSBezierPath()
    inner.lineWidth = rect.width * 0.035
    inner.lineCapStyle = .round
    inner.appendArc(withCenter: center, radius: radius * 0.70, startAngle: 214, endAngle: 392)
    NSColor.white.withAlphaComponent(0.70).setStroke()
    inner.stroke()
    drawSmallArrow(at: NSPoint(x: center.x + radius * 0.59, y: center.y + radius * 0.38),
                   angle: 32,
                   size: rect.width * 0.040,
                   color: .white.withAlphaComponent(0.70))

    let left = NSRect(x: rect.width * 0.20, y: rect.height * 0.38, width: rect.width * 0.26, height: rect.height * 0.18)
    let right = NSRect(x: rect.width * 0.56, y: rect.height * 0.42, width: rect.width * 0.26, height: rect.height * 0.18)
    drawMonitor(left, fill: color(0.02, 0.05, 0.09, 0.45), stroke: .white.withAlphaComponent(0.88), lineWidth: rect.width * 0.021, base: false)
    drawMonitor(right, fill: color(0.02, 0.05, 0.09, 0.45), stroke: .white.withAlphaComponent(0.88), lineWidth: rect.width * 0.021, base: false)

    drawBadge(in: rect, color: color(0.98, 0.61, 0.11), symbol: "arrow.triangle.2.circlepath")
}

func drawCandidateC(in rect: NSRect) {
    drawBackground(in: rect, colors: [
        color(0.05, 0.08, 0.10),
        color(0.11, 0.29, 0.32),
        color(0.12, 0.55, 0.52)
    ])

    let window = NSRect(x: rect.width * 0.17, y: rect.height * 0.27, width: rect.width * 0.66, height: rect.height * 0.49)
    let windowPath = NSBezierPath(roundedRect: window, xRadius: rect.width * 0.055, yRadius: rect.width * 0.055)
    color(0.02, 0.04, 0.05, 0.76).setFill()
    windowPath.fill()
    NSColor.white.withAlphaComponent(0.72).setStroke()
    windowPath.lineWidth = rect.width * 0.018
    windowPath.stroke()

    line(from: NSPoint(x: window.minX, y: window.maxY - rect.height * 0.105),
         to: NSPoint(x: window.maxX, y: window.maxY - rect.height * 0.105),
         width: rect.width * 0.012,
         color: .white.withAlphaComponent(0.22),
         cap: .butt)

    let lightY = window.maxY - rect.height * 0.055
    for (index, lightColor) in [color(1.0, 0.34, 0.32), color(1.0, 0.73, 0.23), color(0.25, 0.86, 0.42)].enumerated() {
        lightColor.setFill()
        let dot = NSRect(x: window.minX + rect.width * (0.055 + CGFloat(index) * 0.048),
                         y: lightY - rect.width * 0.016,
                         width: rect.width * 0.032,
                         height: rect.width * 0.032)
        NSBezierPath(ovalIn: dot).fill()
    }

    let promptY = window.midY + rect.height * 0.025
    line(from: NSPoint(x: window.minX + rect.width * 0.075, y: promptY),
         to: NSPoint(x: window.minX + rect.width * 0.27, y: promptY),
         width: rect.width * 0.025,
         color: color(0.42, 1.0, 0.71, 0.95))
    line(from: NSPoint(x: window.minX + rect.width * 0.075, y: promptY - rect.height * 0.09),
         to: NSPoint(x: window.minX + rect.width * 0.43, y: promptY - rect.height * 0.09),
         width: rect.width * 0.018,
         color: .white.withAlphaComponent(0.58))
    line(from: NSPoint(x: window.minX + rect.width * 0.075, y: promptY - rect.height * 0.16),
         to: NSPoint(x: window.minX + rect.width * 0.31, y: promptY - rect.height * 0.16),
         width: rect.width * 0.018,
         color: .white.withAlphaComponent(0.38))

    drawBadge(in: rect, color: color(0.98, 0.36, 0.16), symbol: "arrow.clockwise")
}

func drawCandidateD(in rect: NSRect) {
    drawBackground(in: rect, colors: [
        color(0.96, 0.97, 1.00),
        color(0.20, 0.70, 0.95),
        color(0.02, 0.45, 0.76)
    ])

    let panel = NSRect(x: rect.width * 0.18, y: rect.height * 0.22, width: rect.width * 0.52, height: rect.height * 0.54)
    let panelPath = NSBezierPath(roundedRect: panel, xRadius: rect.width * 0.07, yRadius: rect.width * 0.07)
    color(0.02, 0.28, 0.47, 0.22).setFill()
    panelPath.fill()
    NSColor.white.withAlphaComponent(0.64).setStroke()
    panelPath.lineWidth = rect.width * 0.018
    panelPath.stroke()

    line(from: NSPoint(x: panel.midX, y: panel.minY + rect.height * 0.07),
         to: NSPoint(x: panel.midX, y: panel.maxY - rect.height * 0.07),
         width: rect.width * 0.030,
         color: .white.withAlphaComponent(0.50))

    drawDottedConnection(from: NSPoint(x: panel.minX + rect.width * 0.09, y: panel.midY + rect.height * 0.07),
                         to: NSPoint(x: panel.maxX - rect.width * 0.09, y: panel.midY - rect.height * 0.05),
                         dots: 6,
                         radius: rect.width * 0.020,
                         color: .white)

    drawCursor(in: NSRect(x: rect.width * 0.46, y: rect.height * 0.36, width: rect.width * 0.26, height: rect.height * 0.36),
               fill: .white,
               stroke: color(0.01, 0.35, 0.55, 0.25))

    drawBadge(in: rect, color: color(0.10, 0.64, 0.42), symbol: "arrow.clockwise")
}

func drawCandidateE(in rect: NSRect) {
    drawBackground(in: rect, colors: [
        color(0.12, 0.19, 0.25),
        color(0.34, 0.60, 0.76),
        color(0.96, 0.61, 0.22)
    ])

    let baseY = rect.height * 0.33
    let left = NSRect(x: rect.width * 0.18, y: baseY, width: rect.width * 0.26, height: rect.height * 0.20)
    let right = NSRect(x: rect.width * 0.57, y: baseY + rect.height * 0.055, width: rect.width * 0.25, height: rect.height * 0.20)
    drawMonitor(left, fill: color(0.02, 0.05, 0.07, 0.38), stroke: .white.withAlphaComponent(0.90), lineWidth: rect.width * 0.021)
    drawMonitor(right, fill: color(0.02, 0.05, 0.07, 0.38), stroke: .white.withAlphaComponent(0.90), lineWidth: rect.width * 0.021)

    let beaconCenter = NSPoint(x: rect.midX, y: rect.height * 0.60)
    for index in 0..<3 {
        let radius = rect.width * (0.10 + CGFloat(index) * 0.082)
        let arc = NSBezierPath()
        arc.lineWidth = rect.width * (0.015 - CGFloat(index) * 0.002)
        arc.lineCapStyle = .round
        arc.appendArc(withCenter: beaconCenter, radius: radius, startAngle: 22, endAngle: 158)
        NSColor.white.withAlphaComponent(0.78 - CGFloat(index) * 0.18).setStroke()
        arc.stroke()
    }

    color(0.98, 0.67, 0.16).setFill()
    NSBezierPath(ovalIn: NSRect(x: beaconCenter.x - rect.width * 0.028,
                                y: beaconCenter.y - rect.width * 0.028,
                                width: rect.width * 0.056,
                                height: rect.width * 0.056)).fill()

    drawBadge(in: rect, color: color(0.09, 0.45, 0.92), symbol: "arrow.clockwise")
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
        throw NSError(domain: "IconCandidates", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render PNG"])
    }

    try png.write(to: url)
}

func saveContactSheet(candidates: [IconCandidate], outputDirectory: URL) throws {
    let tileSize: CGFloat = 320
    let margin: CGFloat = 52
    let labelHeight: CGFloat = 64
    let width = margin + CGFloat(candidates.count) * (tileSize + margin)
    let height = margin * 2 + tileSize + labelHeight
    let image = NSImage(size: NSSize(width: width, height: height))

    image.lockFocus()
    color(0.95, 0.96, 0.97).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    for (index, candidate) in candidates.enumerated() {
        let x = margin + CGFloat(index) * (tileSize + margin)
        let y = margin + labelHeight
        let iconURL = outputDirectory.appendingPathComponent("\(candidate.id).png")
        if let icon = NSImage(contentsOf: iconURL) {
            icon.draw(in: NSRect(x: x, y: y, width: tileSize, height: tileSize),
                      from: .zero,
                      operation: .sourceOver,
                      fraction: 1)
        }

        let label = "\(candidate.id.uppercased())  \(candidate.title)"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: color(0.14, 0.16, 0.19),
            .paragraphStyle: paragraph
        ]
        label.draw(in: NSRect(x: x - 8, y: margin * 0.68, width: tileSize + 16, height: 34), withAttributes: attrs)
    }

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconCandidates", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not render contact sheet"])
    }

    try png.write(to: outputDirectory.appendingPathComponent("contact-sheet.png"))
}

func saveDockPreview(candidates: [IconCandidate], outputDirectory: URL) throws {
    let margin: CGFloat = 42
    let rowGap: CGFloat = 34
    let labelWidth: CGFloat = 150
    let sizes: [CGFloat] = [256, 128, 64]
    let tileWidth = sizes.reduce(CGFloat(0), +) + CGFloat(sizes.count - 1) * rowGap
    let width = margin * 2 + labelWidth + tileWidth
    let rowHeight: CGFloat = 292
    let height = margin * 2 + CGFloat(candidates.count) * rowHeight
    let image = NSImage(size: NSSize(width: width, height: height))

    image.lockFocus()
    color(0.95, 0.96, 0.97).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    for (index, candidate) in candidates.enumerated() {
        let y = height - margin - CGFloat(index + 1) * rowHeight + 18
        let label = candidate.id.uppercased()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: color(0.14, 0.16, 0.19),
            .paragraphStyle: paragraph
        ]
        label.draw(in: NSRect(x: margin, y: y + 106, width: labelWidth, height: 36), withAttributes: attrs)

        var x = margin + labelWidth
        let iconURL = outputDirectory.appendingPathComponent("\(candidate.id).png")
        if let icon = NSImage(contentsOf: iconURL) {
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
        throw NSError(domain: "IconCandidates", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not render dock preview"])
    }

    try png.write(to: outputDirectory.appendingPathComponent("dock-preview.png"))
}

let candidates = [
    IconCandidate(id: "a-bridge", title: "Device Bridge", draw: drawCandidateA),
    IconCandidate(id: "b-cycle", title: "Recovery Cycle", draw: drawCandidateB),
    IconCandidate(id: "c-terminal", title: "Terminal Fix", draw: drawCandidateC),
    IconCandidate(id: "d-pointer", title: "Pointer Rescue", draw: drawCandidateD),
    IconCandidate(id: "e-beacon", title: "Signal Beacon", draw: drawCandidateE)
]

let arguments = CommandLine.arguments
let outputDirectory = URL(fileURLWithPath: arguments.dropFirst().first ?? "Resources/icon-candidates", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for candidate in candidates {
    try saveImage(size: 1024, to: outputDirectory.appendingPathComponent("\(candidate.id).png"), draw: candidate.draw)
}

try saveContactSheet(candidates: candidates, outputDirectory: outputDirectory)
try saveDockPreview(candidates: candidates, outputDirectory: outputDirectory)
print("Generated \(candidates.count) icon candidates in \(outputDirectory.path)")
