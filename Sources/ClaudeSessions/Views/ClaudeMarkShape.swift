import SwiftUI
import AppKit

/// Hand-translated from the provided SVG (viewBox 0 0 24 24, fill-rule evenodd).
struct ClaudeMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let s = min(rect.width, rect.height) / 24.0
        let ox = rect.minX
        let oy = rect.minY
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: ox + x * s, y: oy + y * s)
        }

        // Outer silhouette
        p.move(to: P(20.998, 10.949))
        p.addLine(to: P(24, 10.949))
        p.addLine(to: P(24, 14.051))
        p.addLine(to: P(21, 14.051))
        p.addLine(to: P(21, 17.079))
        p.addLine(to: P(19.513, 17.079))
        p.addLine(to: P(19.513, 20))
        p.addLine(to: P(18, 20))
        p.addLine(to: P(18, 17.079))
        p.addLine(to: P(16.513, 17.079))
        p.addLine(to: P(16.513, 20))
        p.addLine(to: P(15, 20))
        p.addLine(to: P(15, 17.079))
        p.addLine(to: P(9, 17.079))
        p.addLine(to: P(9, 20))
        p.addLine(to: P(7.488, 20))
        p.addLine(to: P(7.488, 17.079))
        p.addLine(to: P(6, 17.079))
        p.addLine(to: P(6, 20))
        p.addLine(to: P(4.487, 20))
        p.addLine(to: P(4.487, 17.079))
        p.addLine(to: P(3, 17.079))
        p.addLine(to: P(3, 14.05))
        p.addLine(to: P(0, 14.05))
        p.addLine(to: P(0, 10.95))
        p.addLine(to: P(3, 10.95))
        p.addLine(to: P(3, 5))
        p.addLine(to: P(20.998, 5))
        p.addLine(to: P(20.998, 10.949))
        p.closeSubpath()

        // Left eye
        p.move(to: P(6, 10.949))
        p.addLine(to: P(7.488, 10.949))
        p.addLine(to: P(7.488, 8.102))
        p.addLine(to: P(6, 8.102))
        p.addLine(to: P(6, 10.949))
        p.closeSubpath()

        // Right eye
        p.move(to: P(16.51, 10.949))
        p.addLine(to: P(18, 10.949))
        p.addLine(to: P(18, 8.102))
        p.addLine(to: P(16.51, 8.102))
        p.addLine(to: P(16.51, 10.949))
        p.closeSubpath()

        return p
    }
}

struct ClaudeMark: View {
    var color: Color = .primary
    var size: CGFloat = 14

    var body: some View {
        ClaudeMarkShape()
            .fill(color, style: FillStyle(eoFill: true))
            .frame(width: size, height: size)
    }
}

/// Template NSImage wrapped as SwiftUI Image — auto-tints to match menu bar appearance.
struct ClaudeMarkTemplateImage: View {
    var size: CGFloat = 15

    var body: some View {
        Image(nsImage: Self.make(size: size))
    }

    private static func make(size: CGFloat) -> NSImage {
        let dim = NSSize(width: size, height: size)
        let image = NSImage(size: dim, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let path = ClaudeMarkShape().path(in: rect).cgPath
            ctx.addPath(path)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillPath(using: .evenOdd)
            return true
        }
        image.isTemplate = true
        return image
    }
}
