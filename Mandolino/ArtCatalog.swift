import UIKit

/// The Art pages: ornate mandalas and zentangle animals with many fine spaces, drawn with a bold
/// outer line and finer lines inside, like a hand-inked coloring book.
enum ArtPage {
    static let mandalas = "art-mandalas"
    static let animals = "art-animals"

    static let templates: [MandalaTemplate] = [
        ("art-lotus", "Lotus mandala"), ("art-paisley", "Paisley mandala"), ("art-feather", "Feather mandala"),
        ("art-sun", "Sun mandala"), ("art-heart", "Heart mandala"), ("art-lace", "Lace mandala")
    ].enumerated().map {
        MandalaTemplate(id: $0.element.0, title: $0.element.1, symbol: "sparkles", difficulty: .art,
                        designID: mandalas, variation: $0.offset)
    } + [
        ("art-wolf", "Wolf"), ("art-owl", "Owl"), ("art-lion", "Lion"),
        ("art-butterfly", "Butterfly"), ("art-elephant", "Elephant"), ("art-peacock", "Peacock")
    ].enumerated().map {
        MandalaTemplate(id: $0.element.0, title: $0.element.1, symbol: "pawprint", difficulty: .art,
                        designID: animals, variation: $0.offset)
    }

    static func draw(_ id: String, in c: CGContext) {
        switch id {
        case "art-lotus": lotus(c)
        case "art-paisley": paisleyMandala(c)
        case "art-feather": featherMandala(c)
        case "art-sun": sunMandala(c)
        case "art-heart": heartMandala(c)
        case "art-lace": laceMandala(c)
        case "art-wolf": wolf(c)
        case "art-owl": owl(c)
        case "art-lion": lion(c)
        case "art-butterfly": butterfly(c)
        case "art-elephant": elephant(c)
        case "art-peacock": peacock(c)
        default: preconditionFailure("Unknown art page: \(id)")
        }
    }
}

// MARK: Drawing helpers

private let center = CGPoint(x: 500, y: 500)
private let fine: CGFloat = 3.5
private let bold: CGFloat = 6.5

private extension CGContext {
    /// A closed shape painted white and outlined, so it covers whatever was drawn behind it.
    func shape(_ path: CGPath, width: CGFloat = fine) {
        setLineWidth(width)
        addPath(path)
        drawPath(using: .fillStroke)
    }

    /// Lines only, without covering anything.
    func lines(_ path: CGPath, width: CGFloat = fine) {
        setLineWidth(width)
        addPath(path)
        strokePath()
    }

    /// A solid black shape, like a nose or a pupil: part of the drawing, not a space to color.
    func ink(_ path: CGPath) {
        setFillColor(UIColor.black.cgColor)
        addPath(path)
        fillPath()
        setFillColor(UIColor.white.cgColor)
    }

    func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, width: CGFloat = fine) {
        shape(CGPath(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2), transform: nil), width: width)
    }

    func ring(_ r: CGFloat, width: CGFloat = fine, at point: CGPoint = center) {
        lines(CGPath(ellipseIn: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2), transform: nil),
              width: width)
    }

    /// A white disc with an outline, hiding everything behind it.
    func disc(_ r: CGFloat, width: CGFloat = fine, at point: CGPoint = center) {
        shape(CGPath(ellipseIn: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2), transform: nil),
              width: width)
    }

    /// Repeats a motif drawn pointing up from the page center, `count` times around it.
    func around(_ count: Int, offset: CGFloat = 0, at point: CGPoint = center, _ motif: () -> Void) {
        for i in 0..<count {
            saveGState()
            translateBy(x: point.x, y: point.y)
            rotate(by: (CGFloat(i) + offset) * 2 * .pi / CGFloat(count))
            motif()
            restoreGState()
        }
    }

    /// Draws inside `path` only, then outlines it again so the clipped pattern ends cleanly on it.
    func inside(_ path: CGPath, width: CGFloat = fine, _ pattern: () -> Void) {
        saveGState()
        addPath(path)
        clip()
        pattern()
        restoreGState()
        lines(path, width: width)
    }

    func segment(_ a: CGPoint, _ b: CGPoint, width: CGFloat = fine) {
        let path = CGMutablePath()
        path.move(to: a)
        path.addLine(to: b)
        lines(path, width: width)
    }
}

/// A petal pointing up from the origin (y grows downward), from radius `r0` to `r1`.
/// `round` 0 makes a pointed lotus tip, 1 a round tip.
private func petal(_ r0: CGFloat, _ r1: CGFloat, width w: CGFloat, round: CGFloat = 0) -> CGPath {
    let length = r1 - r0
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 0, y: -r0))
    for side: CGFloat in [1, -1] {
        let end = side > 0 ? CGPoint(x: 0, y: -r1) : CGPoint(x: 0, y: -r0)
        let near = CGPoint(x: side * w * 1.05, y: -r0 - length * 0.18)
        let far = CGPoint(x: side * w * (0.35 + 0.75 * round), y: -r0 - length * (0.92 + 0.1 * round))
        if side > 0 {
            path.addCurve(to: end, control1: near, control2: far)
        } else {
            path.addCurve(to: end, control1: far, control2: near)
        }
    }
    path.closeSubpath()
    return path
}

/// A teardrop pointing up: round at radius `r0`, pointed at `r1`.
private func teardrop(_ r0: CGFloat, _ r1: CGFloat, width w: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let mid = r0 + w
    path.move(to: CGPoint(x: 0, y: -r1))
    path.addCurve(to: CGPoint(x: w, y: -mid), control1: CGPoint(x: w * 0.25, y: -r1 + (r1 - mid) * 0.35),
                  control2: CGPoint(x: w, y: -mid - (r1 - mid) * 0.45))
    path.addArc(center: CGPoint(x: 0, y: -mid), radius: w, startAngle: 0, endAngle: .pi, clockwise: false)
    path.addCurve(to: CGPoint(x: 0, y: -r1), control1: CGPoint(x: -w, y: -mid - (r1 - mid) * 0.45),
                  control2: CGPoint(x: -w * 0.25, y: -r1 + (r1 - mid) * 0.35))
    path.closeSubpath()
    return path
}

/// Half-circle bumps around a circle of radius `r`, each `depth` deep: a scalloped edge.
private func scallops(_ r: CGFloat, count: Int, depth: CGFloat, at point: CGPoint = center) -> CGPath {
    let path = CGMutablePath()
    for i in 0...count {
        let a = CGFloat(i) * 2 * .pi / CGFloat(count) - .pi / 2
        let p = CGPoint(x: point.x + cos(a) * r, y: point.y + sin(a) * r)
        if i == 0 {
            path.move(to: p)
        } else {
            let m = a - .pi / CGFloat(count)
            let control = CGPoint(x: point.x + cos(m) * (r + depth * 2), y: point.y + sin(m) * (r + depth * 2))
            path.addQuadCurve(to: p, control: control)
        }
    }
    path.closeSubpath()
    return path
}

/// A shape that is the same on both sides of the y axis: the curves trace its right half from
/// `start` (on the axis) to the axis again, and the left half is their mirror image.
private func symmetric(_ start: CGPoint, _ curves: [(CGPoint, CGPoint, CGPoint)]) -> CGPath {
    let path = CGMutablePath()
    path.move(to: start)
    var points = [start]
    for (c1, c2, to) in curves {
        path.addCurve(to: to, control1: c1, control2: c2)
        points.append(to)
    }
    func mirror(_ p: CGPoint) -> CGPoint { CGPoint(x: -p.x, y: p.y) }
    for i in curves.indices.reversed() {
        path.addCurve(to: mirror(points[i]), control1: mirror(curves[i].1), control2: mirror(curves[i].0))
    }
    path.closeSubpath()
    return path
}

private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

/// A heart with its point at radius `r0` and its two lobes reaching `r1`.
private func heart(_ r0: CGFloat, _ r1: CGFloat, width w: CGFloat) -> CGPath {
    let h = r1 - r0
    return symmetric(p(0, -r0), [
        (p(w * 0.35, -r0 - h * 0.2), p(w, -r0 - h * 0.4), p(w, -r0 - h * 0.66)),
        (p(w, -r0 - h * 0.9), p(w * 0.8, -r1), p(w * 0.5, -r1)),
        (p(w * 0.2, -r1), p(0, -r1 + h * 0.06), p(0, -r1 + h * 0.2))
    ])
}

/// A paisley around the origin: a round body of radius `r` with a tail curling up and to the right.
private func paisley(_ r: CGFloat) -> CGPath {
    let path = CGMutablePath()
    path.move(to: p(0, r))
    path.addCurve(to: p(-r, -r * 0.1), control1: p(-r * 0.58, r), control2: p(-r, r * 0.52))
    path.addCurve(to: p(r * 0.85, -r * 2.25), control1: p(-r, -r * 1.05), control2: p(-r * 0.15, -r * 2.05))
    path.addCurve(to: p(r * 0.98, -r * 0.15), control1: p(r * 0.42, -r * 1.75), control2: p(r * 0.8, -r * 1.0))
    path.addCurve(to: p(0, r), control1: p(r * 1.12, r * 0.5), control2: p(r * 0.58, r))
    path.closeSubpath()
    return path
}

private extension CGContext {
    /// A paisley with an inner paisley, an eye with a pupil, and a crown of little dots around it.
    func paisleyMotif(_ r: CGFloat, dots: Bool = true) {
        if dots {
            for i in 0..<9 {
                let a = -.pi * 0.95 + CGFloat(i) * .pi * 0.135
                dot(cos(a) * r * 1.3, sin(a) * r * 1.3 + r * 0.05, r * 0.11)
            }
        }
        shape(paisley(r), width: bold)
        saveGState()
        translateBy(x: r * 0.05, y: -r * 0.12)
        scaleBy(x: 0.68, y: 0.68)
        shape(paisley(r), width: fine / 0.68)
        restoreGState()
        dot(0, r * 0.08, r * 0.36)
        dot(0, r * 0.08, r * 0.14)
    }

    /// A leaf from radius `r0` to `r1` with a midrib and side veins running out to its edge.
    func veinedLeaf(_ r0: CGFloat, _ r1: CGFloat, width w: CGFloat, veins: Int, outline: CGFloat = bold) {
        let leaf = petal(r0, r1, width: w)
        shape(leaf, width: outline)
        inside(leaf, width: outline) {
            segment(p(0, -r0), p(0, -r1))
            let step = (r1 - r0) / CGFloat(veins + 1)
            for i in 1...veins {
                let y = -r0 - step * CGFloat(i)
                segment(p(0, y), p(w * 1.4, y - step * 1.3))
                segment(p(0, y), p(-w * 1.4, y - step * 1.3))
            }
        }
    }
}

// MARK: Mandalas

private func lotus(_ c: CGContext) {
    // Outer crown: pointed tips with an inner line, behind everything else.
    c.around(32, offset: 0.5) {
        c.shape(petal(380, 478, width: 26), width: bold)
        c.lines(petal(398, 458, width: 13))
    }
    c.shape(scallops(372, count: 32, depth: 20), width: bold)
    c.around(32) { c.dot(0, -390, 7) }
    c.ring(352)
    // Small pointed petals peeking out between the big ones.
    c.around(16, offset: 0.5) {
        c.shape(petal(250, 352, width: 44))
        c.shape(petal(268, 330, width: 22))
    }
    // Big lotus petals with three nested outlines, a vein and a teardrop.
    c.around(16) {
        c.shape(petal(218, 362, width: 70), width: bold)
        c.shape(petal(232, 340, width: 50))
        c.shape(petal(246, 318, width: 30))
        c.segment(CGPoint(x: 0, y: -262), CGPoint(x: 0, y: -310))
        c.shape(teardrop(226, 262, width: 9))
    }
    c.disc(222, width: bold)
    c.ring(206)
    c.around(48) { c.segment(CGPoint(x: 0, y: -206), CGPoint(x: 0, y: -222)) }
    // Rounded petals, overlapping like a water lily.
    c.around(12, offset: 0.5) {
        c.shape(petal(110, 206, width: 50, round: 1))
        c.shape(petal(122, 186, width: 30, round: 1))
    }
    c.around(12) {
        c.shape(petal(96, 196, width: 46, round: 0.2), width: bold)
        c.shape(petal(110, 176, width: 26, round: 0.2))
        c.segment(CGPoint(x: 0, y: -122), CGPoint(x: 0, y: -168))
    }
    c.disc(100, width: bold)
    c.around(16) { c.dot(0, -84, 9) }
    c.ring(70)
    c.around(8) {
        c.shape(petal(18, 66, width: 22, round: 0.6))
    }
    c.disc(20)
    c.disc(8)
}

private func paisleyMandala(_ c: CGContext) {
    c.around(24, offset: 0.5) { c.veinedLeaf(395, 478, width: 22, veins: 2) }
    c.around(24) { c.shape(teardrop(392, 440, width: 11)) }
    c.shape(scallops(360, count: 24, depth: 22), width: bold)
    c.around(24) { c.dot(0, -378, 8) }
    c.disc(348)
    // Twelve paisleys turning around the page like a pinwheel.
    c.around(12) {
        c.saveGState()
        c.translateBy(x: 0, y: -290)
        c.rotate(by: -.pi / 2.6)
        c.paisleyMotif(42)
        c.restoreGState()
    }
    c.around(12, offset: 0.5) {
        c.shape(petal(236, 312, width: 20))
        c.shape(petal(250, 296, width: 9))
        c.dot(0, -326, 8)
    }
    c.shape(scallops(226, count: 36, depth: 9))
    c.disc(226, width: bold)
    // A braided band: crossing arcs make a row of little lens shapes.
    c.inside(CGPath(ellipseIn: CGRect(x: 302, y: 302, width: 396, height: 396), transform: nil)) {
        c.around(36) { c.ring(22, at: p(0, -212)) }
    }
    c.disc(190, width: bold)
    c.around(16, offset: 0.5) { c.shape(petal(110, 186, width: 30, round: 0.4)) }
    c.around(16) {
        c.shape(petal(96, 178, width: 26, round: 0.4), width: bold)
        c.shape(petal(110, 160, width: 13, round: 0.4))
    }
    c.disc(100, width: bold)
    c.around(6) {
        c.saveGState()
        c.translateBy(x: 0, y: -58)
        c.rotate(by: -.pi / 2.4)
        c.paisleyMotif(19, dots: false)
        c.restoreGState()
    }
    c.disc(20)
}

private func featherMandala(_ c: CGContext) {
    // Bead tips beyond each feather.
    c.around(16) {
        c.dot(0, -468, 13)
        c.dot(0, -468, 5)
    }
    c.around(16, offset: 0.5) {
        c.veinedLeaf(250, 420, width: 26, veins: 4)
        c.dot(0, -440, 9)
    }
    // Long feathers with a quill and barbs on both sides.
    c.around(16) {
        let feather = petal(150, 452, width: 46, round: 0.35)
        c.shape(feather, width: bold)
        c.inside(feather, width: bold) {
            for i in 0..<8 {
                let y = -196 - CGFloat(i) * 30
                c.segment(p(0, y), p(60, y - 36))
                c.segment(p(0, y), p(-60, y - 36))
            }
        }
        let quill = petal(170, 440, width: 7, round: 1)
        c.shape(quill)
        c.shape(teardrop(392, 432, width: 12))
    }
    c.disc(176, width: bold)
    c.ring(160)
    c.around(32) { c.dot(0, -168, 5) }
    // A sunburst in the middle.
    c.around(24) {
        let ray = CGMutablePath()
        ray.addLines(between: [p(-14, -66), p(0, -150), p(14, -66)])
        ray.closeSubpath()
        c.shape(ray)
    }
    c.around(12, offset: 0.5) { c.shape(petal(60, 128, width: 22, round: 0.3)) }
    c.disc(66, width: bold)
    c.around(12) { c.shape(petal(14, 60, width: 12, round: 0.6)) }
    c.disc(16)
}

private func sunMandala(_ c: CGContext) {
    // Flames all around the edge.
    c.around(36, offset: 0.5) { c.shape(petal(380, 450, width: 14)) }
    c.around(36) {
        let flame = petal(372, 484, width: 24)
        c.shape(flame, width: bold)
        c.lines(petal(392, 456, width: 10))
    }
    c.disc(378, width: bold)
    // A band of triangles pointing in and out.
    c.ring(342)
    c.around(36) {
        let zig = CGMutablePath()
        let a = .pi / 36 as CGFloat
        zig.move(to: p(sin(-a) * 342, -cos(-a) * 342))
        zig.addLine(to: p(0, -378))
        zig.addLine(to: p(sin(a) * 342, -cos(a) * 342))
        c.lines(zig)
    }
    // Long rays with chevrons, short rays between them.
    c.around(12, offset: 0.5) {
        let ray = petal(200, 330, width: 34)
        c.shape(ray)
        c.dot(0, -310, 8)
    }
    c.around(12) {
        let ray = petal(180, 342, width: 52)
        c.shape(ray, width: bold)
        c.inside(ray) {
            for i in 0..<4 {
                let y = -214 - CGFloat(i) * 30
                c.lines({ let v = CGMutablePath(); v.addLines(between: [p(-70, y + 40), p(0, y), p(70, y + 40)]); return v }())
            }
        }
    }
    c.disc(196, width: bold)
    // A wavy ribbon.
    let wave = CGMutablePath()
    for i in 0...720 {
        let a = CGFloat(i) / 720 * 2 * .pi
        let r = 172 + 10 * sin(a * 24)
        let point = p(500 + cos(a) * r, 500 + sin(a) * r)
        if i == 0 { wave.move(to: point) } else { wave.addLine(to: point) }
    }
    c.lines(wave)
    c.ring(150, width: bold)
    // Two squares make an eight-pointed star, with a smaller star inside.
    for turn in [0, 1] {
        c.saveGState()
        c.translateBy(x: 500, y: 500)
        c.rotate(by: CGFloat(turn) * .pi / 4)
        c.shape(CGPath(rect: CGRect(x: -104, y: -104, width: 208, height: 208), transform: nil), width: bold)
        c.restoreGState()
    }
    for turn in [0, 1] {
        c.saveGState()
        c.translateBy(x: 500, y: 500)
        c.rotate(by: CGFloat(turn) * .pi / 4)
        c.lines(CGPath(rect: CGRect(x: -80, y: -80, width: 160, height: 160), transform: nil))
        c.restoreGState()
    }
    c.disc(62, width: bold)
    c.around(16) { c.shape(petal(22, 58, width: 9)) }
    c.disc(24)
    c.disc(9)
}

private func heartMandala(_ c: CGContext) {
    // A lacy edge of little round petals with holes.
    c.around(40) {
        c.shape(petal(410, 470, width: 18, round: 1), width: bold)
        c.dot(0, -448, 5)
    }
    c.shape(scallops(390, count: 20, depth: 18), width: bold)
    c.around(20) { c.dot(0, -406, 9) }
    c.disc(372)
    // Small hearts between the big ones.
    c.around(8, offset: 0.5) {
        c.shape(heart(250, 360, width: 52))
        c.shape(heart(268, 338, width: 32))
        c.dot(0, -228, 10)
    }
    // Big hearts, each with a heart inside a heart and a row of beads.
    c.around(8) {
        c.shape(heart(150, 360, width: 104), width: bold)
        c.shape(heart(176, 330, width: 74))
        c.shape(heart(204, 300, width: 44))
        c.shape(heart(228, 278, width: 20))
    }
    c.around(16, offset: 0.25) { c.dot(0, -190, 8) }
    c.disc(150, width: bold)
    c.ring(132)
    c.around(24) { c.segment(p(0, -132), p(0, -150)) }
    // A flower of hearts in the middle.
    c.around(8) {
        c.shape(heart(28, 124, width: 44), width: bold)
        c.shape(heart(46, 104, width: 22))
    }
    c.disc(30, width: bold)
    c.disc(12)
}

private func laceMandala(_ c: CGContext) {
    // A lace edge: tiny scallops with three holes each.
    c.shape(scallops(432, count: 48, depth: 14), width: bold)
    c.around(48) {
        c.dot(0, -452, 4)
    }
    c.shape(scallops(396, count: 24, depth: 18), width: bold)
    c.around(24) { c.dot(0, -414, 8) }
    c.disc(380)
    // Arched windows.
    c.around(24) {
        let arch = symmetric(p(0, -262), [
            (p(20, -262), p(38, -262), p(38, -262)),
            (p(38, -300), p(38, -330), p(30, -346)),
            (p(20, -366), p(8, -372), p(0, -376))
        ])
        c.shape(arch, width: bold)
        c.shape(petal(276, 352, width: 18, round: 0.5))
    }
    c.disc(262, width: bold)
    // Interlocking circles.
    c.inside(CGPath(ellipseIn: CGRect(x: 262, y: 262, width: 476, height: 476), transform: nil)) {
        c.around(18) { c.ring(52, at: p(0, -196)) }
    }
    c.ring(144, width: bold)
    // The flower of life: six circles around one.
    c.inside(CGPath(ellipseIn: CGRect(x: 356, y: 356, width: 288, height: 288), transform: nil)) {
        c.ring(72)
        c.around(6) { c.ring(72, at: p(0, -72)) }
        c.around(6, offset: 0.5) { c.ring(72, at: p(0, -125)) }
    }
    c.ring(144, width: bold)
    c.disc(18)
}

// MARK: Animal helpers

/// Smooth curves through `points` (Catmull-Rom), continuing the path from where it is.
private func smooth(_ path: CGMutablePath, _ points: [CGPoint]) {
    if path.isEmpty { path.move(to: points[0]) } else { path.addLine(to: points[0]) }
    for i in 0..<(points.count - 1) {
        let p0 = points[max(i - 1, 0)], p1 = points[i], p2 = points[i + 1], p3 = points[min(i + 2, points.count - 1)]
        path.addCurve(to: p2, control1: p(p1.x + (p2.x - p0.x) / 6, p1.y + (p2.y - p0.y) / 6),
                      control2: p(p2.x - (p3.x - p1.x) / 6, p2.y - (p3.y - p1.y) / 6))
    }
}

/// A furry edge along `points`: pointed tufts sticking out to the left of the direction of travel
/// (outward when a shape is traced clockwise), each swept the way the line runs, or against it when
/// `backward` (for the mirrored side of a shape, so both sides sweep alike).
private func fur(_ path: CGMutablePath, _ points: [CGPoint], tufts: Int, depth: CGFloat, backward: Bool = false) {
    var along: [CGFloat] = [0]
    for (a, b) in zip(points, points.dropFirst()) { along.append(along.last! + hypot(b.x - a.x, b.y - a.y)) }
    func at(_ t: CGFloat) -> (point: CGPoint, normal: CGPoint) {
        let d = t * along.last!
        var i = 0
        while i < points.count - 2 && along[i + 1] < d { i += 1 }
        let a = points[i], b = points[i + 1]
        let f = (d - along[i]) / max(along[i + 1] - along[i], 0.001)
        let length = max(hypot(b.x - a.x, b.y - a.y), 0.001)
        return (p(a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f), p((b.y - a.y) / length, -(b.x - a.x) / length))
    }
    if path.isEmpty { path.move(to: points[0]) } else { path.addLine(to: points[0]) }
    func out(_ t: CGFloat, _ amount: CGFloat) -> CGPoint {
        let base = at(t)
        return p(base.point.x + base.normal.x * amount, base.point.y + base.normal.y * amount)
    }
    for i in 0..<tufts {
        let n = CGFloat(tufts), k = CGFloat(i)
        if backward {
            path.addQuadCurve(to: out((k + 0.15) / n, depth), control: out(k / n, depth * 0.2))
            path.addQuadCurve(to: at((k + 1) / n).point, control: out((k + 0.55) / n, depth * 0.75))
        } else {
            path.addQuadCurve(to: out((k + 0.85) / n, depth), control: out((k + 0.45) / n, depth * 0.75))
            path.addQuadCurve(to: at((k + 1) / n).point, control: out((k + 1) / n, depth * 0.2))
        }
    }
}

private func mirrored(_ points: [CGPoint]) -> [CGPoint] { points.reversed().map { p(-$0.x, $0.y) } }

private extension CGContext {
    /// Draws a motif on the right of the page's middle line and again mirrored on the left.
    /// Inside, x = 0 is the middle of the page.
    func bothSides(_ motif: () -> Void) {
        for side: CGFloat in [1, -1] {
            saveGState()
            translateBy(x: 500, y: 0)
            scaleBy(x: side, y: 1)
            motif()
            restoreGState()
        }
    }

    /// Draws with x = 0 in the middle of the page.
    func centered(_ drawing: () -> Void) {
        saveGState()
        translateBy(x: 500, y: 0)
        drawing()
        restoreGState()
    }

    /// Rows of fur tufts pointing down, filling the current clip: each row closes a row of spaces.
    func furRows(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat, row: CGFloat, tuft: CGFloat) {
        var y = top, shift = false
        while y < bottom {
            let path = CGMutablePath()
            var x = left - (shift ? tuft / 2 : 0)
            path.move(to: p(x, y))
            while x < right {
                // Each tip reaches just past the next row, so every tuft is a closed space.
                path.addQuadCurve(to: p(x + tuft / 2, y + row * 1.06), control: p(x + tuft * 0.1, y + row * 0.6))
                path.addQuadCurve(to: p(x + tuft, y), control: p(x + tuft * 0.9, y + row * 0.6))
                x += tuft
            }
            lines(path)
            y += row
            shift.toggle()
        }
    }

    /// An almond eye with an iris, a black pupil and a white glint.
    func eye(_ x: CGFloat, _ y: CGFloat, width w: CGFloat, height h: CGFloat, tilt: CGFloat = 0) {
        saveGState()
        translateBy(x: x, y: y)
        rotate(by: tilt)
        let almond = CGMutablePath()
        almond.move(to: p(-w, 0))
        almond.addQuadCurve(to: p(w, 0), control: p(0, -h * 1.6))
        almond.addQuadCurve(to: p(-w, 0), control: p(0, h * 1.3))
        shape(almond, width: bold)
        dot(0, -h * 0.1, h * 0.72)
        ink(CGPath(ellipseIn: CGRect(x: -h * 0.36, y: -h * 0.46, width: h * 0.72, height: h * 0.72), transform: nil))
        dot(h * 0.12, -h * 0.32, h * 0.12)
        restoreGState()
    }
}

// MARK: Animals

private func wolf(_ c: CGContext) {
    c.centered {
        // The chest ruff behind the head, with rows of fur tufts.
        let ruffSide = [p(150, 520), p(270, 600), p(330, 720), p(310, 840), p(220, 925), p(0, 968)]
        let ruff = CGMutablePath()
        ruff.move(to: p(-150, 520))
        ruff.addLine(to: p(150, 520))
        fur(ruff, ruffSide, tufts: 9, depth: 34)
        fur(ruff, mirrored(ruffSide), tufts: 9, depth: 34, backward: true)
        ruff.closeSubpath()
        c.shape(ruff, width: bold)
        c.inside(ruff, width: bold) {
            c.furRows(top: 610, bottom: 980, left: -360, right: 360, row: 50, tuft: 46)
        }
    }
    // Ears: a furry outer ear and an inner ear full of fine fur lines.
    c.bothSides {
        let ear = CGMutablePath()
        ear.move(to: p(70, 230))
        ear.addQuadCurve(to: p(178, 62), control: p(100, 120))
        ear.addQuadCurve(to: p(268, 330), control: p(262, 150))
        ear.closeSubpath()
        c.shape(ear, width: bold)
        let inner = CGMutablePath()
        inner.move(to: p(105, 240))
        inner.addQuadCurve(to: p(178, 112), control: p(122, 150))
        inner.addQuadCurve(to: p(236, 300), control: p(232, 170))
        inner.closeSubpath()
        c.shape(inner)
        c.inside(inner) {
            for i in 0..<7 {
                let x = 120 + CGFloat(i) * 18
                let path = CGMutablePath()
                path.move(to: p(x - 10, 320))
                path.addQuadCurve(to: p(178 + (x - 175) * 0.35, 130 + abs(x - 175) * 0.8), control: p(x, 220))
                c.lines(path)
            }
        }
    }
    c.centered {
        // The head, with furry cheeks.
        let cheek = [p(250, 360), p(285, 450), p(290, 540), p(250, 620), p(190, 670)]
        let head = CGMutablePath()
        smooth(head, [p(0, 188), p(95, 182), p(170, 215), p(225, 280), p(250, 360)])
        fur(head, cheek, tufts: 6, depth: 30)
        smooth(head, [p(190, 670), p(120, 712), p(0, 742), p(-120, 712), p(-190, 670)])
        fur(head, mirrored(cheek), tufts: 6, depth: 30, backward: true)
        smooth(head, [p(-250, 360), p(-225, 280), p(-170, 215), p(-95, 182), p(0, 188)])
        head.closeSubpath()
        c.shape(head, width: bold)
        c.inside(head, width: bold) {
            // Cheek fur on both sides of the face.
            for side: CGFloat in [1, -1] {
                c.saveGState()
                c.scaleBy(x: side, y: 1)
                let patch = CGPath(ellipseIn: CGRect(x: 150, y: 480, width: 190, height: 250), transform: nil)
                c.inside(patch) {
                    c.furRows(top: 492, bottom: 740, left: 140, right: 350, row: 38, tuft: 34)
                }
                c.restoreGState()
            }
        }
    }
    c.bothSides {
        // A feathered leaf on each side of the forehead, leaning toward the ear.
        c.saveGState()
        c.translateBy(x: 62, y: 318)
        c.rotate(by: 0.62)
        c.veinedLeaf(0, 120, width: 24, veins: 3, outline: fine)
        c.restoreGState()
        // Brows and a sweeping mask line under each eye.
        let brow = CGMutablePath()
        brow.move(to: p(40, 372))
        brow.addQuadCurve(to: p(190, 350), control: p(110, 318))
        brow.addQuadCurve(to: p(52, 392), control: p(110, 340))
        brow.closeSubpath()
        c.shape(brow)
        let mask = CGMutablePath()
        mask.move(to: p(55, 425))
        mask.addQuadCurve(to: p(225, 468), control: p(130, 480))
        mask.addQuadCurve(to: p(70, 445), control: p(130, 505))
        mask.closeSubpath()
        c.shape(mask)
        // Little beads along the edge of the cheek fur.
        for i in 0..<4 {
            c.dot(158 + CGFloat(i) * 30, 500 - CGFloat(i) * 4 + (i == 0 ? 14 : 0), 7)
        }
        // The muzzle's side and the upper lip, with whisker dots.
        let muzzle = CGMutablePath()
        muzzle.move(to: p(30, 380))
        muzzle.addQuadCurve(to: p(70, 590), control: p(40, 500))
        muzzle.addQuadCurve(to: p(150, 660), control: p(95, 650))
        c.lines(muzzle, width: bold)
        let lip = CGMutablePath()
        lip.move(to: p(0, 640))
        lip.addQuadCurve(to: p(120, 668), control: p(50, 690))
        c.lines(lip)
        for (x, y) in [(72, 612), (98, 626), (88, 596)] as [(CGFloat, CGFloat)] {
            c.ink(CGPath(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8), transform: nil))
        }
        c.eye(115, 420, width: 58, height: 22, tilt: -0.12)
    }
    c.centered {
        // Forehead: a rising sun with a flower above it.
        let sun = CGMutablePath()
        sun.addArc(center: p(0, 330), radius: 78, startAngle: .pi, endAngle: 0, clockwise: false)
        sun.closeSubpath()
        c.shape(sun)
        c.inside(sun) {
            for i in 0...12 {
                let a = .pi + CGFloat(i) * .pi / 12
                c.segment(p(cos(a) * 44, 330 + sin(a) * 44), p(cos(a) * 80, 330 + sin(a) * 80))
            }
        }
        let inner = CGMutablePath()
        inner.addArc(center: p(0, 330), radius: 44, startAngle: .pi, endAngle: 0, clockwise: false)
        inner.closeSubpath()
        c.shape(inner)
        c.saveGState()
        c.translateBy(x: 0, y: 330)
        c.shape(teardrop(4, 38, width: 12))
        c.restoreGState()
        c.around(7, offset: 0.5, at: p(0, 230)) { c.shape(petal(8, 32, width: 8, round: 0.6)) }
        c.dot(0, 230, 9)
        // A line of the muzzle down from the sun to the nose.
        c.segment(p(0, 340), p(0, 560))
        let nose = symmetric(p(0, 556), [
            (p(30, 556), p(60, 562), p(60, 590)),
            (p(60, 612), p(30, 634), p(0, 642))
        ])
        c.ink(nose)
        c.segment(p(0, 640), p(0, 660))
        let chin = CGMutablePath()
        chin.move(to: p(-50, 702))
        chin.addQuadCurve(to: p(50, 702), control: p(0, 728))
        c.lines(chin)
    }
}

private extension CGContext {
    /// A round mandala eye: rings, a crown of petals, an iris and a black pupil with a glint.
    func mandalaEye(_ x: CGFloat, _ y: CGFloat, radius r: CGFloat) {
        let point = p(x, y)
        disc(r, width: bold, at: point)
        around(16, at: point) { shape(petal(r * 0.5, r * 0.92, width: r * 0.13, round: 0.5)) }
        disc(r * 0.52, at: point)
        disc(r * 0.36, at: point)
        ink(CGPath(ellipseIn: CGRect(x: x - r * 0.2, y: y - r * 0.2, width: r * 0.4, height: r * 0.4), transform: nil))
        dot(x + r * 0.07, y - r * 0.08, r * 0.06)
    }

    /// The same shape again and again, smaller each time toward `focus`: nested bands to color.
    func nested(_ path: CGPath, toward focus: CGPoint, scales: [CGFloat]) {
        for scale in scales {
            saveGState()
            translateBy(x: focus.x, y: focus.y)
            scaleBy(x: scale, y: scale)
            translateBy(x: -focus.x, y: -focus.y)
            shape(path, width: fine / scale)
            restoreGState()
        }
    }
}

private func owl(_ c: CGContext) {
    c.centered {
        // A branch with leaves at both ends.
        let branch = CGMutablePath()
        smooth(branch, [p(-360, 842), p(0, 828), p(360, 846)])
        smooth(branch, [p(360, 846), p(372, 880)])
        smooth(branch, [p(372, 880), p(0, 872), p(-360, 886)])
        branch.closeSubpath()
        c.shape(branch, width: bold)
        for x: CGFloat in [-240, -90, 120, 260] { c.lines({ let g = CGMutablePath(); g.move(to: p(x, 850)); g.addQuadCurve(to: p(x + 70, 856), control: p(x + 35, 840)); return g }()) }
        for side: CGFloat in [1, -1] {
            for (dx, angle) in [(CGFloat(0), CGFloat(0.5)), (CGFloat(30), CGFloat(1.4))] {
                c.saveGState()
                c.translateBy(x: side * (360 + dx * 0.3), y: 862)
                c.rotate(by: side * angle)
                c.veinedLeaf(0, 120, width: 26, veins: 3, outline: fine)
                c.restoreGState()
            }
        }
        // Tail feathers below the body.
        for angle: CGFloat in [-0.35, 0, 0.35] {
            c.saveGState()
            c.translateBy(x: 0, y: 740)
            c.rotate(by: .pi + angle)
            c.veinedLeaf(0, 150, width: 32, veins: 3)
            c.restoreGState()
        }
        // The body, with a scaled chest.
        let body = symmetric(p(0, 300), [
            (p(120, 300), p(230, 380), p(240, 540)),
            (p(250, 700), p(140, 800), p(0, 810))
        ])
        c.shape(body, width: bold)
        c.inside(body, width: bold) {
            let chest = CGPath(ellipseIn: CGRect(x: -140, y: 470, width: 280, height: 330), transform: nil)
            c.inside(chest) { c.furRows(top: 480, bottom: 820, left: -160, right: 160, row: 40, tuft: 42) }
        }
        for x: CGFloat in [-70, 70] {
            for toe: CGFloat in [-22, 0, 22] {
                c.shape(petal(0, 46, width: 9, round: 1).copy(using: [CGAffineTransform(translationX: x + toe, y: 852).rotated(by: .pi + toe / 60)])!)
            }
        }
    }
    // Wings full of feathers.
    c.bothSides {
        let wing = CGMutablePath()
        smooth(wing, [p(150, 420), p(258, 520), p(272, 660), p(205, 800), p(180, 760), p(150, 640), p(150, 420)])
        wing.closeSubpath()
        c.shape(wing, width: bold)
        c.inside(wing, width: bold) {
            c.furRows(top: 450, bottom: 690, left: 120, right: 300, row: 46, tuft: 40)
            for i in 0..<3 {
                let x = 175 + CGFloat(i) * 30
                c.segment(p(x, 690), p(x + 10 - CGFloat(i) * 22, 820))
            }
            c.segment(p(120, 690), p(300, 690))
        }
    }
    c.centered {
        // The head with ear tufts.
        let head = symmetric(p(0, 190), [
            (p(60, 175), p(130, 150), p(200, 90)),
            (p(205, 160), p(250, 230), p(250, 320)),
            (p(250, 420), p(150, 480), p(0, 485))
        ])
        c.shape(head, width: bold)
        c.inside(head, width: bold) {
            for side: CGFloat in [1, -1] {
                let tuft = CGMutablePath()
                tuft.move(to: p(side * 120, 175))
                tuft.addQuadCurve(to: p(side * 200, 95), control: p(side * 175, 160))
                c.lines(tuft)
                tuft.move(to: p(side * 150, 190))
                c.lines({ let t = CGMutablePath(); t.move(to: p(side * 150, 195)); t.addQuadCurve(to: p(side * 215, 130), control: p(side * 200, 180)); return t }())
            }
            // Feathers on the forehead, pointing down to the beak.
            for i in 0..<5 {
                c.saveGState()
                c.translateBy(x: 0, y: 360)
                c.rotate(by: .pi + (CGFloat(i) - 2) * 0.32)
                c.shape(petal(-150, -60, width: 14, round: 0.5))
                c.restoreGState()
            }
        }
        c.mandalaEye(-102, 330, radius: 92)
        c.mandalaEye(102, 330, radius: 92)
        let beak = symmetric(p(0, 360), [(p(18, 368), p(26, 392), p(0, 440))])
        c.shape(beak, width: bold)
    }
}

private func lion(_ c: CGContext) {
    let face = p(500, 500)
    // A mane like a mandala: two layers of flame-shaped locks.
    c.around(22, offset: 0.5, at: face) {
        c.shape(petal(250, 470, width: 50), width: bold)
        c.lines(petal(280, 440, width: 26))
    }
    c.around(22, at: face) {
        c.veinedLeaf(200, 400, width: 52, veins: 4)
    }
    c.disc(232, width: bold, at: face)
    c.around(44, at: face) { c.dot(0, -216, 7) }
    c.centered {
        // Round ears.
        for side: CGFloat in [1, -1] {
            c.dot(side * 150, 318, 54, width: bold)
            c.dot(side * 150, 318, 30)
        }
        let head = symmetric(p(0, 296), [
            (p(110, 296), p(185, 340), p(190, 470)),
            (p(195, 580), p(120, 690), p(0, 700))
        ])
        c.shape(head, width: bold)
        // Forehead ornament: a crown of petals and a teardrop.
        c.around(5, offset: -2, at: p(0, 380)) { c.shape(petal(14, 52, width: 12, round: 0.5)) }
        c.saveGState()
        c.translateBy(x: 0, y: 380)
        c.rotate(by: .pi)
        c.shape(teardrop(10, 70, width: 12))
        c.restoreGState()
        c.dot(0, 380, 12)
        for side: CGFloat in [1, -1] {
            let brow = CGMutablePath()
            brow.move(to: p(side * 40, 420))
            brow.addQuadCurve(to: p(side * 150, 400), control: p(side * 100, 380))
            c.lines(brow, width: bold)
            c.eye(side * 92, 452, width: 44, height: 17, tilt: side * -0.1)
            // Cheek patterns.
            for i in 0..<3 {
                c.dot(side * (150 - CGFloat(i) * 8), 510 + CGFloat(i) * 34, 12)
            }
        }
        // The muzzle: two round pads with whisker dots, a nose and a mouth.
        let bridge = CGMutablePath()
        bridge.move(to: p(-34, 440))
        bridge.addQuadCurve(to: p(-48, 560), control: p(-30, 520))
        bridge.move(to: p(34, 440))
        bridge.addQuadCurve(to: p(48, 560), control: p(30, 520))
        c.lines(bridge)
        for side: CGFloat in [1, -1] {
            c.dot(side * 50, 610, 52, width: bold)
            for (dx, dy) in [(22, -14), (40, 4), (18, 18)] as [(CGFloat, CGFloat)] {
                c.ink(CGPath(ellipseIn: CGRect(x: side * (50 + dx) - 4, y: 610 + dy - 4, width: 8, height: 8), transform: nil))
            }
        }
        let chin = symmetric(p(0, 640), [(p(30, 640), p(40, 668), p(0, 690))])
        c.shape(chin)
        let nose = symmetric(p(0, 540), [
            (p(30, 540), p(56, 548), p(54, 566)),
            (p(48, 586), p(18, 600), p(0, 604))
        ])
        c.ink(nose)
    }
}

private func butterfly(_ c: CGContext) {
    c.bothSides {
        // The lower wing, with nested bands and an eye spot.
        let lower = CGMutablePath()
        smooth(lower, [p(25, 500), p(200, 470), p(330, 520), p(370, 640), p(300, 760), p(250, 880), p(180, 820), p(60, 680), p(25, 500)])
        lower.closeSubpath()
        c.shape(lower, width: bold)
        c.inside(lower, width: bold) {
            c.nested(lower, toward: p(220, 640), scales: [0.78, 0.52])
            for i in 0..<9 {
                let a = -0.4 + CGFloat(i) * 0.19
                c.segment(p(30 + cos(a) * 130, 520 + sin(a) * 130), p(30 + cos(a) * 420, 520 + sin(a) * 420))
            }
            c.nested(lower, toward: p(220, 640), scales: [0.52])
            c.dot(230, 650, 38)
            c.dot(230, 650, 20)
            c.ink(CGPath(ellipseIn: CGRect(x: 222, y: 642, width: 16, height: 16), transform: nil))
        }
        // The upper wing.
        let upper = CGMutablePath()
        smooth(upper, [p(25, 480), p(30, 330), p(150, 170), p(330, 110), p(440, 150), p(455, 300), p(400, 420), p(250, 490), p(25, 480)])
        upper.closeSubpath()
        c.shape(upper, width: bold)
        c.inside(upper, width: bold) {
            c.nested(upper, toward: p(230, 320), scales: [0.8, 0.56, 0.3])
            for i in 0..<10 {
                let a = -1.45 + CGFloat(i) * 0.17
                c.segment(p(30 + cos(a) * 150, 470 + sin(a) * 150), p(30 + cos(a) * 520, 470 + sin(a) * 520))
            }
            c.nested(upper, toward: p(230, 320), scales: [0.56, 0.3])
            c.saveGState()
            c.translateBy(x: 235, y: 320)
            c.rotate(by: 0.9)
            c.paisleyMotif(26, dots: false)
            c.restoreGState()
            // Dots along the outer edge.
            for i in 0..<9 {
                let t = CGFloat(i) / 8
                c.dot(170 + t * 270 - t * t * 40, 165 - t * 30 + t * t * 160, 9)
            }
        }
        // Antennae with curled tips.
        let antenna = CGMutablePath()
        antenna.move(to: p(8, 240))
        antenna.addQuadCurve(to: p(110, 90), control: p(30, 120))
        c.lines(antenna, width: bold)
        c.dot(116, 84, 14, width: bold)
    }
    c.centered {
        // The body: head, chest and a striped tail.
        let tail = symmetric(p(0, 330), [(p(34, 330), p(36, 600), p(0, 780))])
        c.shape(tail, width: bold)
        c.inside(tail, width: bold) {
            for i in 0..<10 { c.segment(p(-50, 380 + CGFloat(i) * 38), p(50, 370 + CGFloat(i) * 38)) }
        }
        c.shape(CGPath(ellipseIn: CGRect(x: -34, y: 250, width: 68, height: 110), transform: nil), width: bold)
        c.dot(0, 232, 30, width: bold)
    }
}

private func elephant(_ c: CGContext) {
    // Big ears, decorated like fans.
    c.bothSides {
        let ear = CGMutablePath()
        smooth(ear, [p(120, 250), p(270, 190), p(410, 230), p(460, 380), p(430, 540), p(330, 640), p(200, 620), p(150, 500)])
        ear.closeSubpath()
        c.shape(ear, width: bold)
        c.inside(ear, width: bold) {
            c.nested(ear, toward: p(300, 420), scales: [0.8])
            for i in 0..<16 {
                let a = CGFloat(i) * .pi / 8
                c.dot(300 + cos(a) * 158 * 1.05, 420 + sin(a) * 175, 9)
            }
            c.nested(ear, toward: p(300, 420), scales: [0.8, 0.55])
            c.saveGState()
            c.translateBy(x: 300, y: 430)
            c.rotate(by: 0.5)
            c.paisleyMotif(40)
            c.restoreGState()
        }
        // Tusks.
        let tusk = CGMutablePath()
        tusk.move(to: p(70, 560))
        tusk.addQuadCurve(to: p(170, 760), control: p(90, 700))
        tusk.addQuadCurve(to: p(112, 570), control: p(150, 640))
        tusk.closeSubpath()
        c.shape(tusk, width: bold)
    }
    c.centered {
        // The head and trunk in one shape, with rings along the trunk.
        let head = CGMutablePath()
        let right = [p(0, 170), p(130, 185), p(200, 290), p(190, 420), p(120, 520), p(80, 620), p(66, 760), p(80, 860), p(120, 910)]
        smooth(head, right)
        smooth(head, [p(120, 910), p(40, 930), p(-40, 900)])
        smooth(head, [p(-40, 900), p(-62, 760), p(-80, 620), p(-120, 520), p(-190, 420), p(-200, 290), p(-130, 185), p(0, 170)])
        head.closeSubpath()
        c.shape(head, width: bold)
        c.inside(head, width: bold) {
            for i in 0..<9 {
                let y = 600 + CGFloat(i) * 34
                let ring = CGMutablePath()
                ring.move(to: p(-120, y))
                ring.addQuadCurve(to: p(140, y), control: p(10, y + 22))
                c.lines(ring)
            }
            // Dots between the rings of the trunk.
            for i in 0..<8 {
                c.dot(i.isMultiple(of: 2) ? -28 : 28, 628 + CGFloat(i) * 34, 7)
            }
            // A cap of scallops above the headdress.
            for i in 0..<7 {
                let x = -150 + CGFloat(i) * 50
                let arch = CGMutablePath()
                arch.move(to: p(x - 25, 320))
                arch.addQuadCurve(to: p(x + 25, 320), control: p(x, 150))
                c.lines(arch)
                c.dot(x, 236 + abs(x) * 0.25, 7)
            }
            // A jeweled headdress across the forehead.
            let band = CGMutablePath()
            band.move(to: p(-180, 300))
            band.addQuadCurve(to: p(180, 300), control: p(0, 210))
            band.addLine(to: p(180, 330))
            band.addQuadCurve(to: p(-180, 330), control: p(0, 240))
            band.closeSubpath()
            c.shape(band)
            for i in 0..<9 {
                let x = -160 + CGFloat(i) * 40
                let y = 330 - (1 - pow(x / 180, 2)) * 45
                c.saveGState()
                c.translateBy(x: x, y: y)
                c.rotate(by: .pi)
                c.shape(teardrop(-2, 44, width: 10))
                c.restoreGState()
            }
        }
        c.dot(0, 290, 54, width: bold)
        c.around(12, at: p(0, 290)) { c.shape(petal(14, 48, width: 10, round: 0.5)) }
        c.dot(0, 290, 16)
        for side: CGFloat in [1, -1] {
            c.eye(side * 115, 420, width: 34, height: 13, tilt: side * 0.25)
            // A little flower on each cheek.
            c.around(8, at: p(side * 92, 488)) { c.shape(petal(10, 32, width: 9, round: 0.6)) }
            c.dot(side * 92, 488, 10)
        }
    }
}

private func peacock(_ c: CGContext) {
    let fan = p(500, 640)
    // A fan of long feathers, each with an eye at its tip.
    for i in 0..<15 {
        c.saveGState()
        c.translateBy(x: fan.x, y: fan.y)
        c.rotate(by: (CGFloat(i) - 7) * .pi / 15.5)
        let feather = petal(150, 560, width: 46, round: 0.7)
        c.shape(feather, width: bold)
        c.inside(feather, width: bold) {
            for k in 0..<7 {
                let y = -190 - CGFloat(k) * 34
                c.segment(p(0, y), p(60, y - 44))
                c.segment(p(0, y), p(-60, y - 44))
            }
            c.segment(p(0, -150), p(0, -440))
        }
        c.shape(CGPath(ellipseIn: CGRect(x: -38, y: -548, width: 76, height: 104), transform: nil))
        c.shape(CGPath(ellipseIn: CGRect(x: -26, y: -530, width: 52, height: 72), transform: nil))
        c.shape(heart(-512, -470, width: 18).copy(using: [CGAffineTransform(scaleX: 1, y: -1)])!)
        c.restoreGState()
    }
    // Shorter feathers in front.
    for i in 0..<14 {
        c.saveGState()
        c.translateBy(x: fan.x, y: fan.y)
        c.rotate(by: (CGFloat(i) - 6.5) * .pi / 15.5)
        c.veinedLeaf(110, 300, width: 30, veins: 3)
        c.restoreGState()
    }
    c.disc(150, width: bold, at: fan)
    c.centered {
        c.around(30, at: p(0, 640)) { c.dot(0, -134, 6) }
        // The body with scales, a slim neck and a small head with a crest.
        let body = symmetric(p(0, 360), [
            (p(36, 360), p(42, 420), p(40, 470)),
            (p(110, 540), p(130, 700), p(60, 800)),
            (p(40, 830), p(20, 840), p(0, 840))
        ])
        c.shape(body, width: bold)
        c.inside(body, width: bold) {
            c.furRows(top: 520, bottom: 860, left: -150, right: 150, row: 36, tuft: 32)
        }
        for side: CGFloat in [1, -1] {
            let leg = CGMutablePath()
            leg.move(to: p(side * 30, 835))
            leg.addLine(to: p(side * 40, 930))
            leg.move(to: p(side * 40, 930))
            leg.addLine(to: p(side * 70, 950))
            leg.move(to: p(side * 40, 930))
            leg.addLine(to: p(side * 20, 955))
            c.lines(leg, width: bold)
        }
        for angle: CGFloat in [-0.35, 0, 0.35] {
            let stalk = CGMutablePath()
            stalk.move(to: p(0, 320))
            stalk.addLine(to: p(sin(angle) * 80, 320 - cos(angle) * 80))
            c.lines(stalk)
            c.dot(sin(angle) * 88, 320 - cos(angle) * 88, 10)
        }
        c.dot(0, 350, 40, width: bold)
        for side: CGFloat in [1, -1] {
            c.ink(CGPath(ellipseIn: CGRect(x: side * 18 - 6, y: 336, width: 12, height: 12), transform: nil))
        }
        let beak = symmetric(p(0, 356), [(p(9, 358), p(10, 368), p(0, 382))])
        c.ink(beak)
    }
}
