import UIKit

enum Difficulty: String, CaseIterable, Identifiable {
    case easy, medium, hard, expert
    var id: String { rawValue }
    var title: String { L.text(rawValue.capitalized) }
}

struct MandalaTemplate: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let difficulty: Difficulty
    let designID: String
    let variation: Int

    init(id: String, title: String, symbol: String, difficulty: Difficulty,
         designID: String? = nil, variation: Int = 0) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.difficulty = difficulty
        self.designID = designID ?? id
        self.variation = variation
    }

    var localizedTitle: String {
        L.text(title) + (variation == 0 ? "" : " \(variation + 1)")
    }

    private static let originals: [MandalaTemplate] = [
        .init(id: "flower", title: "Flower", symbol: "camera.macro", difficulty: .easy),
        .init(id: "butterfly", title: "Butterfly", symbol: "butterfly", difficulty: .easy),
        .init(id: "fish", title: "Fish", symbol: "fish", difficulty: .easy),
        .init(id: "turtle", title: "Turtle", symbol: "tortoise", difficulty: .easy),
        .init(id: "rabbit", title: "Rabbit", symbol: "hare", difficulty: .easy),
        .init(id: "ladybug", title: "Ladybug", symbol: "ladybug", difficulty: .easy),
        .init(id: "sunflower", title: "Sunflower", symbol: "sun.max", difficulty: .medium),
        .init(id: "owl", title: "Owl", symbol: "bird", difficulty: .medium),
        .init(id: "cat", title: "Cat", symbol: "cat", difficulty: .medium),
        .init(id: "lotus", title: "Lotus", symbol: "camera.macro", difficulty: .medium),
        .init(id: "hedgehog", title: "Hedgehog", symbol: "pawprint", difficulty: .medium),
        .init(id: "snail", title: "Snail", symbol: "leaf", difficulty: .medium),
        .init(id: "rosette", title: "Rosette", symbol: "seal", difficulty: .hard),
        .init(id: "lion", title: "Lion", symbol: "pawprint", difficulty: .hard),
        .init(id: "fox", title: "Fox", symbol: "pawprint", difficulty: .hard),
        .init(id: "peacock", title: "Peacock", symbol: "bird", difficulty: .hard),
        .init(id: "elephant", title: "Elephant", symbol: "pawprint", difficulty: .hard),
        .init(id: "bear", title: "Bear", symbol: "teddybear", difficulty: .hard),
        .init(id: "kaleidoscope", title: "Kaleidoscope", symbol: "sparkles", difficulty: .expert),
        .init(id: "star-garden", title: "Star garden", symbol: "star", difficulty: .expert),
        .init(id: "lace-flower", title: "Lace flower", symbol: "camera.macro", difficulty: .expert),
        .init(id: "owl-mosaic", title: "Owl mosaic", symbol: "bird", difficulty: .expert),
        .init(id: "penguin-mosaic", title: "Penguin mosaic", symbol: "bird", difficulty: .expert),
        .init(id: "bee-mosaic", title: "Bee mosaic", symbol: "ladybug", difficulty: .expert)
    ]

    static let all: [MandalaTemplate] = originals + originals.flatMap { base in
        (1...5).map { variant in
            MandalaTemplate(id: "\(base.id)-\(variant)", title: base.title, symbol: base.symbol,
                            difficulty: base.difficulty, designID: base.id, variation: variant)
        }
    }

    func draw(in context: CGContext, size: Int) {
        context.saveGState()
        context.scaleBy(x: CGFloat(size) / 1000, y: CGFloat(size) / 1000)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.setLineWidth(6)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        if variation > 0 {
            let count: Int
            switch difficulty {
            case .easy: count = 4 + variation * 2
            case .medium: count = 10 + variation * 3
            case .hard: count = 20 + variation * 4
            case .expert: count = 40 + variation * 8
            }
            let scale = versionFrame(context, variation: variation, count: count,
                                     jewel: difficulty == .easy ? 17 : 10)
            context.translateBy(x: 500 * (1 - scale), y: 500 * (1 - scale))
            context.scaleBy(x: scale, y: scale)
        }
        switch designID {
        case "flower":
            petals(context, count: 8, radius: 360, length: 255, width: 175)
            circle(context, 500, 500, 125)
        case "sunflower":
            petals(context, count: 16, radius: 420, length: 270, width: 95, pointed: true)
            ring(context, inner: 80, outer: 165, count: 12)
            circle(context, 500, 500, 80)
        case "lotus":
            petals(context, count: 16, radius: 425, length: 240, width: 150, pointed: true)
            petals(context, count: 8, radius: 280, length: 170, width: 155)
            ring(context, inner: 65, outer: 135, count: 8)
            circle(context, 500, 500, 65)
        case "rosette":
            petals(context, count: 24, radius: 440, length: 190, width: 110, pointed: true)
            ring(context, inner: 245, outer: 310, count: 24)
            petals(context, count: 12, radius: 240, length: 125, width: 105, pointed: true)
            ring(context, inner: 55, outer: 135, count: 12)
            circle(context, 500, 500, 55)
        case "butterfly": butterfly(context)
        case "fish": fish(context)
        case "turtle": turtle(context)
        case "owl":
            ring(context, inner: 405, outer: 440, count: 12)
            owl(context)
        case "cat":
            ring(context, inner: 405, outer: 440, count: 12)
            cat(context)
        case "lion":
            ornateBorder(context)
            lion(context)
        case "fox":
            ornateBorder(context)
            fox(context)
        case "peacock":
            ornateBorder(context)
            peacock(context)
        case "kaleidoscope":
            ring(context, inner: 395, outer: 440, count: 48)
            jeweledRing(context, inner: 335, outer: 395, count: 48, jewel: 10)
            ring(context, inner: 270, outer: 335, count: 36)
            petals(context, count: 24, radius: 270, length: 105, width: 70, pointed: true)
            jeweledRing(context, inner: 120, outer: 180, count: 24, jewel: 8)
            ring(context, inner: 55, outer: 120, count: 16)
            circle(context, 500, 500, 55)
        case "star-garden":
            petals(context, count: 32, radius: 440, length: 130, width: 90, pointed: true)
            jeweledRing(context, inner: 275, outer: 345, count: 32, jewel: 12)
            petals(context, count: 16, radius: 270, length: 120, width: 95, pointed: true)
            ring(context, inner: 175, outer: 230, count: 32)
            jeweledRing(context, inner: 60, outer: 150, count: 24, jewel: 8)
            circle(context, 500, 500, 60)
            for i in 0..<32 {
                let angle = CGFloat(i) * .pi * 2 / 32 - .pi / 2
                circle(context, 500 + 380 * cos(angle), 500 + 380 * sin(angle), 9)
            }
        case "lace-flower":
            jeweledRing(context, inner: 350, outer: 440, count: 48, jewel: 12)
            petals(context, count: 24, radius: 340, length: 130, width: 90)
            jeweledRing(context, inner: 150, outer: 230, count: 32, jewel: 10)
            petals(context, count: 12, radius: 150, length: 80, width: 75, pointed: true)
            ring(context, inner: 20, outer: 70, count: 12)
            circle(context, 500, 500, 20)
        case "rabbit": rabbit(context)
        case "ladybug": ladybug(context)
        case "hedgehog":
            ring(context, inner: 405, outer: 440, count: 12)
            hedgehog(context)
        case "snail":
            ring(context, inner: 405, outer: 440, count: 12)
            snail(context)
        case "elephant":
            ornateBorder(context)
            elephant(context)
        case "bear":
            ornateBorder(context)
            bear(context)
        case "penguin-mosaic":
            mosaicRings(context)
            penguin(context)
        case "bee-mosaic":
            mosaicRings(context)
            bee(context)
        case "owl-mosaic":
            ring(context, inner: 335, outer: 365, count: 48)
            jeweledRing(context, inner: 375, outer: 400, count: 48, jewel: 6)
            jeweledRing(context, inner: 410, outer: 440, count: 48, jewel: 8)
            owl(context)
            for x: CGFloat in [405, 595] {
                ring(context, inner: 40, outer: 78, count: 12, center: CGPoint(x: x, y: 410))
                circle(context, x, 410, 16)
            }
        default:
            preconditionFailure("Unknown coloring template: \(id)")
        }
        context.restoreGState()
    }
}

private func ellipse(_ context: CGContext, _ rect: CGRect) {
    context.addEllipse(in: rect)
    context.drawPath(using: .fillStroke)
}

private func circle(_ context: CGContext, _ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) {
    ellipse(context, CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
}

private func polygon(_ context: CGContext, _ points: [CGPoint]) {
    guard let first = points.first else { return }
    context.move(to: first)
    for point in points.dropFirst() { context.addLine(to: point) }
    context.closePath()
    context.drawPath(using: .fillStroke)
}

private func petals(_ context: CGContext, count: Int, radius: CGFloat, length: CGFloat,
                    width: CGFloat, pointed: Bool = false) {
    for i in 0..<count {
        context.saveGState()
        context.translateBy(x: 500, y: 500)
        context.rotate(by: CGFloat(i) * .pi * 2 / CGFloat(count))
        if pointed {
            context.move(to: CGPoint(x: 0, y: -radius))
            context.addQuadCurve(to: CGPoint(x: 0, y: -radius + length),
                                 control: CGPoint(x: width, y: -radius + length * 0.55))
            context.addQuadCurve(to: CGPoint(x: 0, y: -radius),
                                 control: CGPoint(x: -width, y: -radius + length * 0.55))
            context.closePath()
            context.drawPath(using: .fillStroke)
        } else {
            ellipse(context, CGRect(x: -width / 2, y: -radius, width: width, height: length))
        }
        context.restoreGState()
    }
}

private func ring(_ context: CGContext, inner: CGFloat, outer: CGFloat, count: Int,
                  center: CGPoint = CGPoint(x: 500, y: 500)) {
    for i in 0..<count {
        let a = CGFloat(i) * .pi * 2 / CGFloat(count)
        let b = CGFloat(i + 1) * .pi * 2 / CGFloat(count)
        context.move(to: CGPoint(x: center.x + inner * cos(a), y: center.y + inner * sin(a)))
        context.addLine(to: CGPoint(x: center.x + outer * cos(a), y: center.y + outer * sin(a)))
        context.addArc(center: center, radius: outer, startAngle: a, endAngle: b, clockwise: false)
        context.addLine(to: CGPoint(x: center.x + inner * cos(b), y: center.y + inner * sin(b)))
        context.addArc(center: center, radius: inner, startAngle: b, endAngle: a, clockwise: true)
        context.closePath()
        context.drawPath(using: .fillStroke)
    }
}

private func ornateBorder(_ context: CGContext) {
    ring(context, inner: 390, outer: 440, count: 24)
    for i in 0..<24 {
        let angle = (CGFloat(i) + 0.5) * .pi * 2 / 24
        circle(context, 500 + 415 * cos(angle), 500 + 415 * sin(angle), 12)
    }
}

private func jeweledRing(_ context: CGContext, inner: CGFloat, outer: CGFloat,
                         count: Int, jewel: CGFloat) {
    ring(context, inner: inner, outer: outer, count: count)
    let radius = (inner + outer) / 2
    for i in 0..<count {
        let angle = (CGFloat(i) + 0.5) * .pi * 2 / CGFloat(count)
        circle(context, 500 + radius * cos(angle), 500 + radius * sin(angle), jewel)
    }
}

private func eyes(_ context: CGContext, left: CGFloat, right: CGFloat, y: CGFloat,
                  radius: CGFloat = 48) {
    for x in [left, right] {
        circle(context, x, y, radius)
        circle(context, x, y, radius * 0.3)
    }
}

private func butterfly(_ context: CGContext) {
    for left in [true, false] {
        ellipse(context, CGRect(x: left ? 210 : 500, y: 220, width: 290, height: 350))
        ellipse(context, CGRect(x: left ? 250 : 500, y: 520, width: 250, height: 230))
        ellipse(context, CGRect(x: left ? 290 : 565, y: 310, width: 145, height: 165))
        circle(context, left ? 365 : 635, 630, 57)
    }
    ellipse(context, CGRect(x: 462, y: 300, width: 76, height: 450))
    circle(context, 500, 285, 55)
    eyes(context, left: 480, right: 520, y: 278, radius: 12)
}

private func fish(_ context: CGContext) {
    polygon(context, [CGPoint(x: 300, y: 470), CGPoint(x: 110, y: 330),
                      CGPoint(x: 110, y: 670), CGPoint(x: 300, y: 540)])
    polygon(context, [CGPoint(x: 380, y: 340), CGPoint(x: 510, y: 205), CGPoint(x: 620, y: 340)])
    polygon(context, [CGPoint(x: 390, y: 660), CGPoint(x: 510, y: 790), CGPoint(x: 610, y: 660)])
    ellipse(context, CGRect(x: 245, y: 300, width: 560, height: 400))
    eyes(context, left: 690, right: 690, y: 450, radius: 48)
    for x: CGFloat in [355, 470, 580] {
        ellipse(context, CGRect(x: x - 42, y: 450, width: 84, height: 155))
    }
    ellipse(context, CGRect(x: 685, y: 545, width: 65, height: 75))
}

private func turtle(_ context: CGContext) {
    ellipse(context, CGRect(x: 435, y: 115, width: 130, height: 210))
    for x: CGFloat in [215, 665] {
        for y: CGFloat in [335, 645] {
            ellipse(context, CGRect(x: x, y: y, width: 120, height: 150))
        }
    }
    polygon(context, [CGPoint(x: 465, y: 755), CGPoint(x: 500, y: 875), CGPoint(x: 535, y: 755)])
    circle(context, 500, 550, 250)
    ring(context, inner: 125, outer: 250, count: 6, center: CGPoint(x: 500, y: 550))
    circle(context, 500, 550, 125)
    eyes(context, left: 470, right: 530, y: 195, radius: 17)
}

private func owl(_ context: CGContext) {
    ellipse(context, CGRect(x: 290, y: 355, width: 420, height: 450))
    ellipse(context, CGRect(x: 305, y: 510, width: 95, height: 210))
    ellipse(context, CGRect(x: 600, y: 510, width: 95, height: 210))
    polygon(context, [CGPoint(x: 275, y: 400), CGPoint(x: 290, y: 210),
                      CGPoint(x: 395, y: 285), CGPoint(x: 605, y: 285),
                      CGPoint(x: 710, y: 210), CGPoint(x: 725, y: 400),
                      CGPoint(x: 665, y: 520), CGPoint(x: 500, y: 555),
                      CGPoint(x: 335, y: 520)])
    eyes(context, left: 405, right: 595, y: 410, radius: 83)
    circle(context, 405, 410, 48)
    circle(context, 595, 410, 48)
    polygon(context, [CGPoint(x: 465, y: 465), CGPoint(x: 535, y: 465), CGPoint(x: 500, y: 520)])
    for row in 0..<3 {
        for column in 0..<3 {
            ellipse(context, CGRect(x: 412 + column * 58, y: 585 + row * 59, width: 48, height: 43))
        }
    }
}

private func cat(_ context: CGContext) {
    ellipse(context, CGRect(x: 670, y: 520, width: 100, height: 260))
    ellipse(context, CGRect(x: 325, y: 430, width: 350, height: 380))
    ellipse(context, CGRect(x: 367, y: 610, width: 266, height: 160))
    for x: CGFloat in [390, 505] {
        ellipse(context, CGRect(x: x, y: 735, width: 105, height: 75))
    }
    polygon(context, [CGPoint(x: 295, y: 355), CGPoint(x: 295, y: 165), CGPoint(x: 445, y: 270)])
    polygon(context, [CGPoint(x: 555, y: 270), CGPoint(x: 705, y: 165), CGPoint(x: 705, y: 355)])
    ellipse(context, CGRect(x: 280, y: 250, width: 440, height: 340))
    eyes(context, left: 405, right: 595, y: 400, radius: 52)
    for x: CGFloat in [430, 510] {
        ellipse(context, CGRect(x: x, y: 467, width: 60, height: 65))
    }
    polygon(context, [CGPoint(x: 477, y: 460), CGPoint(x: 523, y: 460), CGPoint(x: 500, y: 495)])
    for x: CGFloat in [440, 500, 560] {
        polygon(context, [CGPoint(x: x - 18, y: 285), CGPoint(x: x + 18, y: 285),
                          CGPoint(x: x, y: 340)])
    }
    for x: CGFloat in [335, 665] {
        circle(context, x, 470, 20)
        circle(context, x + (x < 500 ? 14 : -14), 520, 16)
    }
    for x: CGFloat in [417, 500, 583] {
        polygon(context, [CGPoint(x: x, y: 635), CGPoint(x: x + 26, y: 685),
                          CGPoint(x: x, y: 730), CGPoint(x: x - 26, y: 685)])
    }
}

private func lion(_ context: CGContext) {
    ring(context, inner: 195, outer: 335, count: 20)
    circle(context, 500, 500, 195)
    for x: CGFloat in [355, 645] { circle(context, x, 370, 45) }
    eyes(context, left: 425, right: 575, y: 465, radius: 48)
    for x: CGFloat in [445, 555] {
        ellipse(context, CGRect(x: x - 52, y: 530, width: 104, height: 80))
    }
    polygon(context, [CGPoint(x: 460, y: 520), CGPoint(x: 540, y: 520), CGPoint(x: 500, y: 565)])
    ellipse(context, CGRect(x: 465, y: 615, width: 70, height: 40))
    for x: CGFloat in [390, 610] {
        circle(context, x, 540, 16)
        circle(context, x, 580, 12)
    }
}

private func fox(_ context: CGContext) {
    polygon(context, [CGPoint(x: 270, y: 245), CGPoint(x: 390, y: 315),
                      CGPoint(x: 500, y: 280), CGPoint(x: 610, y: 315),
                      CGPoint(x: 730, y: 245), CGPoint(x: 690, y: 540),
                      CGPoint(x: 580, y: 700), CGPoint(x: 500, y: 755),
                      CGPoint(x: 420, y: 700), CGPoint(x: 310, y: 540)])
    polygon(context, [CGPoint(x: 295, y: 280), CGPoint(x: 365, y: 325), CGPoint(x: 320, y: 395)])
    polygon(context, [CGPoint(x: 705, y: 280), CGPoint(x: 635, y: 325), CGPoint(x: 680, y: 395)])
    polygon(context, [CGPoint(x: 310, y: 540), CGPoint(x: 445, y: 490),
                      CGPoint(x: 500, y: 665), CGPoint(x: 500, y: 755),
                      CGPoint(x: 420, y: 700)])
    polygon(context, [CGPoint(x: 690, y: 540), CGPoint(x: 555, y: 490),
                      CGPoint(x: 500, y: 665), CGPoint(x: 500, y: 755),
                      CGPoint(x: 580, y: 700)])
    eyes(context, left: 405, right: 595, y: 465, radius: 42)
    polygon(context, [CGPoint(x: 458, y: 630), CGPoint(x: 542, y: 630), CGPoint(x: 500, y: 680)])
    for x: CGFloat in [420, 500, 580] {
        polygon(context, [CGPoint(x: x, y: 335), CGPoint(x: x + 23, y: 380),
                          CGPoint(x: x, y: 420), CGPoint(x: x - 23, y: 380)])
    }
    circle(context, 420, 585, 18)
    circle(context, 580, 585, 18)
}

private func peacock(_ context: CGContext) {
    for i in 0..<11 {
        context.saveGState()
        context.translateBy(x: 500, y: 640)
        context.rotate(by: (CGFloat(i) - 5) * .pi / 15)
        ellipse(context, CGRect(x: -46, y: -430, width: 92, height: 420))
        ellipse(context, CGRect(x: -32, y: -400, width: 64, height: 115))
        circle(context, 0, -345, 18)
        context.restoreGState()
    }
    ellipse(context, CGRect(x: 410, y: 500, width: 180, height: 280))
    ellipse(context, CGRect(x: 465, y: 385, width: 70, height: 260))
    circle(context, 500, 390, 55)
    eyes(context, left: 480, right: 520, y: 380, radius: 12)
    polygon(context, [CGPoint(x: 480, y: 415), CGPoint(x: 520, y: 415), CGPoint(x: 500, y: 450)])
    for x: CGFloat in [443, 505] {
        ellipse(context, CGRect(x: x, y: 590, width: 52, height: 115))
    }
    for x: CGFloat in [475, 500, 525] { circle(context, x, 310, 14) }
}

/// Draws the frame of a page version and returns how much to shrink the design to fit inside it.
/// Each version has its own style, so the six pages of a design no longer look almost the same.
private func versionFrame(_ context: CGContext, variation: Int, count: Int, jewel: CGFloat) -> CGFloat {
    let petalWidth = min(2 * .pi * 395 / CGFloat(count) * 0.75, 110)
    func fitting(_ inner: CGFloat) -> CGFloat { (inner - 10) / 440 }
    switch variation {
    case 1:
        // Exactly the frame and size this version had before the others got their own styles, so
        // pages colored in it still line up with the template (the eraser restores template lines).
        jeweledRing(context, inner: 365, outer: 440, count: count, jewel: jewel)
        return 0.66 + 0.025
    case 2:
        circle(context, 500, 500, 350)
        petals(context, count: count, radius: 440, length: 95, width: petalWidth)
        return fitting(350)
    case 3:
        circle(context, 500, 500, 345)
        petals(context, count: count, radius: 440, length: 100, width: petalWidth * 0.6, pointed: true)
        return fitting(345)
    case 4:
        jeweledRing(context, inner: 365, outer: 440, count: count, jewel: jewel)
        ring(context, inner: 330, outer: 360, count: count)
        return fitting(330)
    default:
        circle(context, 500, 500, 440)
        circle(context, 500, 500, 350)
        let stars = max(6, count / 2)
        for i in 0..<stars {
            let angle = CGFloat(i) * .pi * 2 / CGFloat(stars)
            star(context, center: CGPoint(x: 500 + 395 * cos(angle), y: 500 + 395 * sin(angle)),
                 radius: min(34, 2 * .pi * 395 / CGFloat(stars) * 0.35))
        }
        return fitting(350)
    }
}

private func star(_ context: CGContext, center: CGPoint, radius: CGFloat) {
    polygon(context, (0..<10).map { i in
        let r = i.isMultiple(of: 2) ? radius : radius * 0.45
        let angle = CGFloat(i) * .pi / 5 - .pi / 2
        return CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
    })
}

private func mosaicRings(_ context: CGContext) {
    ring(context, inner: 335, outer: 365, count: 48)
    jeweledRing(context, inner: 375, outer: 400, count: 48, jewel: 6)
    jeweledRing(context, inner: 410, outer: 440, count: 48, jewel: 8)
    ring(context, inner: 285, outer: 330, count: 24)
}

private func line(_ context: CGContext, _ a: CGPoint, _ b: CGPoint) {
    context.move(to: a)
    context.addLine(to: b)
    context.strokePath()
}

private func rabbit(_ context: CGContext) {
    for x: CGFloat in [360, 530] {
        ellipse(context, CGRect(x: x, y: 110, width: 110, height: 300))
        ellipse(context, CGRect(x: x + 25, y: 150, width: 60, height: 220))
    }
    circle(context, 690, 770, 50)
    ellipse(context, CGRect(x: 320, y: 540, width: 360, height: 330))
    ellipse(context, CGRect(x: 410, y: 640, width: 180, height: 190))
    for x: CGFloat in [330, 540] {
        ellipse(context, CGRect(x: x, y: 820, width: 130, height: 70))
    }
    circle(context, 500, 430, 140)
    eyes(context, left: 450, right: 550, y: 410, radius: 22)
    polygon(context, [CGPoint(x: 485, y: 465), CGPoint(x: 515, y: 465), CGPoint(x: 500, y: 485)])
    for x: CGFloat in [420, 580] { circle(context, x, 470, 18) }
}

private func ladybug(_ context: CGContext) {
    for y: CGFloat in [420, 560, 700] {
        ellipse(context, CGRect(x: 190, y: y - 20, width: 130, height: 40))
        ellipse(context, CGRect(x: 680, y: y - 20, width: 130, height: 40))
    }
    line(context, CGPoint(x: 460, y: 220), CGPoint(x: 400, y: 150))
    line(context, CGPoint(x: 540, y: 220), CGPoint(x: 600, y: 150))
    circle(context, 400, 150, 22)
    circle(context, 600, 150, 22)
    circle(context, 500, 560, 250)
    ellipse(context, CGRect(x: 390, y: 190, width: 220, height: 170))
    line(context, CGPoint(x: 500, y: 355), CGPoint(x: 500, y: 810))
    for spot in [(400, 470, 40), (600, 470, 40), (380, 620, 45), (620, 620, 45), (440, 740, 32), (560, 740, 32)] {
        circle(context, CGFloat(spot.0), CGFloat(spot.1), CGFloat(spot.2))
    }
    for x: CGFloat in [455, 545] { circle(context, x, 260, 18) }
}

private func hedgehog(_ context: CGContext) {
    let center = CGPoint(x: 470, y: 580)
    for i in 0..<13 {
        let angle = (-172 + CGFloat(i) * 13.5) * .pi / 180
        let half: CGFloat = 6.75 * .pi / 180
        polygon(context, [
            CGPoint(x: center.x + 230 * cos(angle - half), y: center.y + 230 * sin(angle - half)),
            CGPoint(x: center.x + 370 * cos(angle), y: center.y + 370 * sin(angle)),
            CGPoint(x: center.x + 230 * cos(angle + half), y: center.y + 230 * sin(angle + half)),
        ])
    }
    for x: CGFloat in [330, 520] {
        ellipse(context, CGRect(x: x, y: 740, width: 100, height: 70))
    }
    ellipse(context, CGRect(x: 250, y: 380, width: 440, height: 400))
    ellipse(context, CGRect(x: 580, y: 520, width: 230, height: 170))
    circle(context, 805, 600, 30)
    circle(context, 670, 560, 24)
    circle(context, 670, 560, 10)
    circle(context, 600, 470, 40)
    for spot in [(380, 560), (450, 640), (360, 680), (480, 520)] {
        circle(context, CGFloat(spot.0), CGFloat(spot.1), 22)
    }
}

private func snail(_ context: CGContext) {
    ellipse(context, CGRect(x: 190, y: 640, width: 620, height: 150))
    ellipse(context, CGRect(x: 670, y: 450, width: 140, height: 260))
    line(context, CGPoint(x: 710, y: 470), CGPoint(x: 680, y: 330))
    line(context, CGPoint(x: 770, y: 470), CGPoint(x: 810, y: 340))
    circle(context, 680, 330, 24)
    circle(context, 810, 340, 24)
    let shell = CGPoint(x: 430, y: 520)
    circle(context, shell.x, shell.y, 220)
    ring(context, inner: 160, outer: 220, count: 10, center: shell)
    ring(context, inner: 105, outer: 160, count: 8, center: shell)
    ring(context, inner: 55, outer: 105, count: 6, center: shell)
    circle(context, shell.x, shell.y, 55)
    circle(context, 740, 540, 14)
}

private func elephant(_ context: CGContext) {
    for left in [true, false] {
        ellipse(context, CGRect(x: left ? 170 : 570, y: 300, width: 260, height: 330))
        ellipse(context, CGRect(x: left ? 205 : 625, y: 345, width: 170, height: 240))
    }
    ellipse(context, CGRect(x: 330, y: 260, width: 340, height: 340))
    polygon(context, [CGPoint(x: 440, y: 600), CGPoint(x: 470, y: 610), CGPoint(x: 400, y: 690)])
    polygon(context, [CGPoint(x: 530, y: 610), CGPoint(x: 560, y: 600), CGPoint(x: 600, y: 690)])
    polygon(context, [CGPoint(x: 455, y: 540), CGPoint(x: 545, y: 540), CGPoint(x: 540, y: 700),
                      CGPoint(x: 575, y: 760), CGPoint(x: 560, y: 800), CGPoint(x: 505, y: 790),
                      CGPoint(x: 480, y: 720), CGPoint(x: 460, y: 640)])
    eyes(context, left: 430, right: 570, y: 420, radius: 30)
    let mark = CGPoint(x: 500, y: 320)
    ring(context, inner: 22, outer: 50, count: 8, center: mark)
    circle(context, mark.x, mark.y, 22)
}

private func bear(_ context: CGContext) {
    for x: CGFloat in [330, 670] {
        circle(context, x, 260, 75)
        circle(context, x, 260, 40)
    }
    polygon(context, [CGPoint(x: 500, y: 700), CGPoint(x: 395, y: 645), CGPoint(x: 395, y: 755)])
    polygon(context, [CGPoint(x: 500, y: 700), CGPoint(x: 605, y: 645), CGPoint(x: 605, y: 755)])
    circle(context, 500, 700, 28)
    circle(context, 500, 440, 220)
    ellipse(context, CGRect(x: 400, y: 470, width: 200, height: 150))
    ellipse(context, CGRect(x: 460, y: 485, width: 80, height: 55))
    eyes(context, left: 415, right: 585, y: 390, radius: 30)
    for x: CGFloat in [365, 635] { circle(context, x, 520, 25) }
    for x: CGFloat in [450, 500, 550] { circle(context, x, 290, 16) }
}

private func penguin(_ context: CGContext) {
    ellipse(context, CGRect(x: 320, y: 420, width: 80, height: 220))
    ellipse(context, CGRect(x: 600, y: 420, width: 80, height: 220))
    ellipse(context, CGRect(x: 360, y: 250, width: 280, height: 480))
    ellipse(context, CGRect(x: 400, y: 380, width: 200, height: 330))
    for x: CGFloat in [410, 510] {
        ellipse(context, CGRect(x: x, y: 715, width: 80, height: 40))
    }
    eyes(context, left: 455, right: 545, y: 330, radius: 22)
    polygon(context, [CGPoint(x: 480, y: 365), CGPoint(x: 520, y: 365), CGPoint(x: 500, y: 400)])
    for y: CGFloat in [490, 560, 630] { circle(context, 500, y, 20) }
}

private func bee(_ context: CGContext) {
    ellipse(context, CGRect(x: 380, y: 270, width: 170, height: 210))
    ellipse(context, CGRect(x: 520, y: 270, width: 170, height: 210))
    polygon(context, [CGPoint(x: 690, y: 505), CGPoint(x: 760, y: 520), CGPoint(x: 690, y: 535)])
    ellipse(context, CGRect(x: 330, y: 410, width: 360, height: 220))
    // Stripes run exactly from edge to edge of the body, so each one splits it into closed spaces.
    for x: CGFloat in [430, 510, 590] {
        let half = 110 * sqrt(1 - pow((x - 510) / 180, 2)) + 2
        line(context, CGPoint(x: x, y: 520 - half), CGPoint(x: x, y: 520 + half))
    }
    line(context, CGPoint(x: 285, y: 460), CGPoint(x: 270, y: 395))
    line(context, CGPoint(x: 315, y: 455), CGPoint(x: 330, y: 385))
    circle(context, 270, 395, 18)
    circle(context, 330, 385, 18)
    circle(context, 300, 520, 80)
    eyes(context, left: 275, right: 330, y: 505, radius: 16)
}
