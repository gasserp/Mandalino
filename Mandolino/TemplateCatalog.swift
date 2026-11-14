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
        .init(id: "dolphin", title: "Dolphin", symbol: "fish", difficulty: .easy),
        .init(id: "whale", title: "Whale", symbol: "fish", difficulty: .easy),
        .init(id: "frog", title: "Frog", symbol: "leaf", difficulty: .easy),
        .init(id: "duck", title: "Duck", symbol: "bird", difficulty: .easy),
        .init(id: "mouse", title: "Mouse", symbol: "pawprint", difficulty: .easy),
        .init(id: "sunflower", title: "Sunflower", symbol: "sun.max", difficulty: .medium),
        .init(id: "owl", title: "Owl", symbol: "bird", difficulty: .medium),
        .init(id: "cat", title: "Cat", symbol: "cat", difficulty: .medium),
        .init(id: "lotus", title: "Lotus", symbol: "camera.macro", difficulty: .medium),
        .init(id: "hedgehog", title: "Hedgehog", symbol: "pawprint", difficulty: .medium),
        .init(id: "snail", title: "Snail", symbol: "leaf", difficulty: .medium),
        .init(id: "dog", title: "Dog", symbol: "dog", difficulty: .medium),
        .init(id: "pig", title: "Pig", symbol: "pawprint", difficulty: .medium),
        .init(id: "sheep", title: "Sheep", symbol: "cloud", difficulty: .medium),
        .init(id: "octopus", title: "Octopus", symbol: "fish", difficulty: .medium),
        .init(id: "seahorse", title: "Seahorse", symbol: "fish", difficulty: .medium),
        .init(id: "rosette", title: "Rosette", symbol: "seal", difficulty: .hard),
        .init(id: "lion", title: "Lion", symbol: "pawprint", difficulty: .hard),
        .init(id: "fox", title: "Fox", symbol: "pawprint", difficulty: .hard),
        .init(id: "peacock", title: "Peacock", symbol: "bird", difficulty: .hard),
        .init(id: "elephant", title: "Elephant", symbol: "pawprint", difficulty: .hard),
        .init(id: "bear", title: "Bear", symbol: "teddybear", difficulty: .hard),
        .init(id: "horse", title: "Horse", symbol: "pawprint", difficulty: .hard),
        .init(id: "giraffe", title: "Giraffe", symbol: "pawprint", difficulty: .hard),
        .init(id: "squirrel", title: "Squirrel", symbol: "leaf", difficulty: .hard),
        .init(id: "koala", title: "Koala", symbol: "pawprint", difficulty: .hard),
        .init(id: "crab", title: "Crab", symbol: "fish", difficulty: .hard),
        .init(id: "kaleidoscope", title: "Kaleidoscope", symbol: "sparkles", difficulty: .expert),
        .init(id: "star-garden", title: "Star garden", symbol: "star", difficulty: .expert),
        .init(id: "lace-flower", title: "Lace flower", symbol: "camera.macro", difficulty: .expert),
        .init(id: "owl-mosaic", title: "Owl mosaic", symbol: "bird", difficulty: .expert),
        .init(id: "penguin-mosaic", title: "Penguin mosaic", symbol: "bird", difficulty: .expert),
        .init(id: "bee-mosaic", title: "Bee mosaic", symbol: "ladybug", difficulty: .expert),
        .init(id: "unicorn", title: "Unicorn", symbol: "sparkles", difficulty: .expert),
        .init(id: "deer", title: "Deer", symbol: "pawprint", difficulty: .expert),
        .init(id: "panda", title: "Panda", symbol: "pawprint", difficulty: .expert),
        .init(id: "parrot", title: "Parrot", symbol: "bird", difficulty: .expert),
        .init(id: "dinosaur", title: "Dinosaur", symbol: "lizard", difficulty: .expert)
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
        if let animal = PatternAnimal.named(designID) {
            animal.draw(context, style: variation, difficulty: difficulty)
            context.restoreGState()
            return
        }
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

// MARK: Pattern animals

/// An animal whose body is filled with a mandala pattern, like a zentangle animal. Each of its six
/// versions uses another pattern, finer on harder levels.
struct PatternAnimal {
    /// Parts drawn before the body (tails, fins, ears, legs).
    let behind: (CGContext) -> Void
    /// The area filled with the pattern.
    let body: CGPath
    /// Where round patterns (rosette, sun) are centered.
    let center: CGPoint
    /// Parts drawn over the body (heads, eyes, wings, feet).
    let front: (CGContext) -> Void

    static let ids = ["dolphin", "whale", "frog", "duck", "mouse",
                      "dog", "pig", "sheep", "octopus", "seahorse",
                      "horse", "giraffe", "squirrel", "koala", "crab",
                      "unicorn", "deer", "panda", "parrot", "dinosaur"]

    func draw(_ context: CGContext, style: Int, difficulty: Difficulty) {
        if difficulty == .expert {
            // Expert pages put the animal on a round mandala background instead of making its own
            // pattern so fine that it turns black.
            let page = CGRect(x: 30, y: 30, width: 940, height: 940)
            context.saveGState()
            context.addEllipse(in: page)
            context.clip()
            context.setLineWidth(4)
            drawPattern(context, style: style.isMultiple(of: 2) ? 5 : 0, in: page,
                        center: CGPoint(x: 500, y: 500), spacing: 80)
            context.restoreGState()
            context.addEllipse(in: page)
            context.strokePath()
        }
        behind(context)
        context.addPath(body)
        context.drawPath(using: .fillStroke)
        context.saveGState()
        context.addPath(body)
        context.clip()
        context.setLineWidth(4)
        let spacing: CGFloat
        switch difficulty {
        case .easy: spacing = 125
        case .medium: spacing = 62
        case .hard: spacing = 62
        case .expert: spacing = 46
        }
        drawPattern(context, style: style, in: body.boundingBox, center: center, spacing: spacing)
        context.restoreGState()
        context.addPath(body)
        context.strokePath()
        front(context)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func named(_ id: String) -> PatternAnimal? {
        switch id {
        case "dolphin":
            return PatternAnimal(behind: { c in
                blob(c, [(215, 555), (120, 490), (95, 520), (160, 585), (110, 655), (150, 665), (235, 590)])
                blob(c, [(490, 352), (530, 262), (562, 232), (590, 262), (625, 338)])
                blob(c, [(590, 478), (555, 575), (590, 588), (665, 488)])
                for bubble in [(880, 300, 24), (925, 235, 16), (860, 215, 12)] {
                    circle(c, CGFloat(bubble.0), CGFloat(bubble.1), CGFloat(bubble.2))
                }
            }, body: smooth([(890, 447), (840, 425), (785, 368), (640, 328), (480, 343), (340, 405), (240, 492),
                             (198, 560), (228, 578), (330, 505), (470, 475), (620, 482), (760, 482), (850, 468)]),
            center: CGPoint(x: 560, y: 420), front: { c in
                eye(c, 785, 405, 16)
                curve(c, (888, 455), control: (850, 472), to: (800, 460))
            })
        case "whale":
            return PatternAnimal(behind: { c in
                blob(c, [(235, 500), (140, 380), (105, 400), (165, 500), (95, 575), (130, 600), (240, 545)])
                line(c, CGPoint(x: 640, y: 335), CGPoint(x: 640, y: 255))
                for drop in [(600, 235, 28), (680, 235, 28), (640, 190, 30)] {
                    circle(c, CGFloat(drop.0), CGFloat(drop.1), CGFloat(drop.2))
                }
            }, body: smooth([(865, 525), (835, 430), (710, 368), (530, 362), (370, 410), (265, 478), (215, 520),
                             (265, 560), (410, 610), (610, 645), (790, 615)]),
            center: CGPoint(x: 540, y: 500), front: { c in
                eye(c, 770, 495, 15)
                curve(c, (860, 548), control: (760, 595), to: (650, 565))
                blob(c, [(560, 600), (520, 695), (575, 705), (635, 612)])
            })
        case "frog":
            return PatternAnimal(behind: { c in
                oval(c, 270, 720, 130, 80, -20)
                oval(c, 730, 720, 130, 80, 20)
            }, body: smooth([(500, 390), (655, 440), (725, 570), (690, 730), (500, 790), (310, 730), (275, 570), (345, 440)]),
            center: CGPoint(x: 500, y: 610), front: { c in
                for x: CGFloat in [385, 615] {
                    circle(c, x, 385, 75)
                    circle(c, x, 385, 32)
                }
                curve(c, (400, 520), control: (500, 578), to: (600, 520))
                oval(c, 400, 790, 70, 35, 0)
                oval(c, 600, 790, 70, 35, 0)
            })
        case "duck":
            return PatternAnimal(behind: { c in
                polygon(c, [CGPoint(x: 440, y: 660), CGPoint(x: 400, y: 745), CGPoint(x: 480, y: 745)])
                polygon(c, [CGPoint(x: 570, y: 660), CGPoint(x: 530, y: 745), CGPoint(x: 610, y: 745)])
                polygon(c, [CGPoint(x: 770, y: 470), CGPoint(x: 865, y: 395), CGPoint(x: 840, y: 505)])
            }, body: smooth([(260, 540), (330, 460), (460, 440), (620, 460), (760, 430), (820, 470), (780, 580),
                             (660, 665), (450, 680), (300, 630)]),
            center: CGPoint(x: 560, y: 560), front: { c in
                polygon(c, [CGPoint(x: 210, y: 355), CGPoint(x: 105, y: 392), CGPoint(x: 210, y: 425)])
                circle(c, 300, 370, 110)
                eye(c, 275, 345, 15)
                blob(c, [(460, 500), (640, 480), (720, 545), (610, 615), (480, 600)])
            })
        case "mouse":
            return PatternAnimal(behind: { c in
                curve(c, (630, 770), control: (870, 830), to: (850, 610))
                for x: CGFloat in [355, 645] {
                    circle(c, x, 240, 95)
                    circle(c, x, 240, 55)
                }
            }, body: smooth([(500, 430), (625, 490), (685, 650), (625, 790), (500, 820), (375, 790), (315, 650), (375, 490)]),
            center: CGPoint(x: 500, y: 650), front: { c in
                circle(c, 500, 345, 135)
                eye(c, 450, 320, 18)
                eye(c, 550, 320, 18)
                circle(c, 500, 390, 20)
                for (a, b) in [((470, 400), (380, 385)), ((470, 412), (385, 428)), ((530, 400), (620, 385)), ((530, 412), (615, 428))] {
                    line(c, CGPoint(x: a.0, y: a.1), CGPoint(x: b.0, y: b.1))
                }
                oval(c, 430, 815, 55, 28, 0)
                oval(c, 570, 815, 55, 28, 0)
            })
        case "dog":
            return PatternAnimal(behind: { c in
                blob(c, [(680, 780), (800, 700), (835, 615), (800, 605), (760, 690), (660, 740)])
            }, body: smooth([(500, 470), (640, 520), (705, 690), (665, 850), (500, 875), (335, 850), (295, 690), (360, 520)]),
            center: CGPoint(x: 500, y: 700), front: { c in
                circle(c, 500, 330, 150)
                let ear: [(CGFloat, CGFloat)] = [(380, 215), (290, 250), (260, 430), (320, 465), (385, 330)]
                blob(c, ear)
                blob(c, ear.map { (1000 - $0.0, $0.1) })
                oval(c, 500, 390, 95, 70, 0)
                oval(c, 500, 360, 32, 21, 0)
                line(c, CGPoint(x: 500, y: 381), CGPoint(x: 500, y: 425))
                eye(c, 440, 290, 20)
                eye(c, 560, 290, 20)
                oval(c, 420, 870, 60, 30, 0)
                oval(c, 580, 870, 60, 30, 0)
            })
        case "pig":
            return PatternAnimal(behind: { c in
                oval(c, 380, 820, 55, 70, 0)
                oval(c, 620, 820, 55, 70, 0)
                polygon(c, [CGPoint(x: 370, y: 250), CGPoint(x: 330, y: 130), CGPoint(x: 455, y: 205)])
                polygon(c, [CGPoint(x: 630, y: 250), CGPoint(x: 670, y: 130), CGPoint(x: 545, y: 205)])
                curve(c, (740, 600), control: (840, 560), to: (790, 520))
                curve(c, (790, 520), control: (750, 500), to: (775, 470))
            }, body: smooth([(500, 420), (690, 470), (760, 620), (700, 780), (500, 830), (300, 780), (240, 620), (310, 470)]),
            center: CGPoint(x: 500, y: 640), front: { c in
                circle(c, 500, 340, 150)
                oval(c, 500, 395, 72, 48, 0)
                circle(c, 474, 395, 12)
                circle(c, 526, 395, 12)
                eye(c, 440, 300, 16)
                eye(c, 560, 300, 16)
            })
        case "sheep":
            return PatternAnimal(behind: { c in
                for x: CGFloat in [380, 460, 620, 700] {
                    polygon(c, [CGPoint(x: x, y: 690), CGPoint(x: x + 40, y: 690), CGPoint(x: x + 40, y: 860), CGPoint(x: x, y: 860)])
                }
            }, body: scallop(center: CGPoint(x: 545, y: 560), rx: 260, ry: 190, bumps: 16),
            center: CGPoint(x: 560, y: 560), front: { c in
                oval(c, 205, 405, 62, 30, -25)
                oval(c, 375, 405, 62, 30, 25)
                oval(c, 290, 480, 100, 135, 0)
                for x: CGFloat in [255, 325] { circle(c, x, 360, 38) }
                eye(c, 258, 470, 15)
                eye(c, 322, 470, 15)
                oval(c, 290, 548, 26, 16, 0)
            })
        case "octopus":
            return PatternAnimal(behind: { c in
                for k in 0..<6 {
                    let x0 = 370 + CGFloat(k) * 52, x1 = 150 + CGFloat(k) * 140
                    var left: [(CGFloat, CGFloat)] = [], right: [(CGFloat, CGFloat)] = []
                    for step in 0...5 {
                        let t = CGFloat(step) / 5
                        let x = x0 + (x1 - x0) * t + sin(t * .pi * 2 + CGFloat(k)) * 35 * t
                        let y = 520 + 360 * t, w = 38 - 26 * t
                        left.append((x - w, y))
                        right.append((x + w, y))
                    }
                    blob(c, left + right.reversed())
                }
            }, body: smooth([(500, 170), (650, 230), (710, 390), (650, 530), (500, 575), (350, 530), (290, 390), (350, 230)]),
            center: CGPoint(x: 500, y: 330), front: { c in
                eye(c, 430, 420, 40)
                eye(c, 570, 420, 40)
                curve(c, (450, 495), control: (500, 528), to: (550, 495))
            })
        case "seahorse":
            return PatternAnimal(behind: { c in
                blob(c, [(612, 420), (705, 455), (700, 560), (628, 535)])
                polygon(c, [CGPoint(x: 480, y: 175), CGPoint(x: 500, y: 110), CGPoint(x: 525, y: 168),
                            CGPoint(x: 545, y: 115), CGPoint(x: 560, y: 172)])
                blob(c, [(500, 690), (565, 700), (565, 800), (610, 862), (540, 895), (468, 830), (470, 740)])
            }, body: smooth([(470, 170), (560, 165), (605, 235), (565, 310), (615, 410), (628, 530), (580, 640), (510, 705),
                             (455, 650), (468, 520), (470, 400), (478, 320), (440, 275), (330, 282), (325, 240), (430, 228)]),
            center: CGPoint(x: 545, y: 470), front: { c in
                eye(c, 510, 225, 16)
                curve(c, (540, 830), control: (520, 790), to: (548, 780))
            })
        case "horse":
            return PatternAnimal(behind: { c in
                polygon(c, [CGPoint(x: 600, y: 215), CGPoint(x: 625, y: 95), CGPoint(x: 668, y: 228)])
                blob(c, horseMane)
            }, body: smooth(horseHead), center: CGPoint(x: 560, y: 560), front: { c in
                polygon(c, [CGPoint(x: 545, y: 205), CGPoint(x: 560, y: 80), CGPoint(x: 610, y: 210)])
                blob(c, [(560, 195), (470, 215), (430, 290), (500, 300), (585, 245)])
                oval(c, 455, 345, 30, 18, -35)
                circle(c, 455, 345, 8)
                oval(c, 268, 628, 20, 12, -60)
                curve(c, (255, 690), control: (290, 705), to: (330, 695))
            })
        case "unicorn":
            // The horse facing right, with a horn, a wavier mane and flowers in it.
            let m: ([(CGFloat, CGFloat)]) -> [(CGFloat, CGFloat)] = { $0.map { (1000 - $0.0, $0.1) } }
            return PatternAnimal(behind: { c in
                polygon(c, [CGPoint(x: 400, y: 215), CGPoint(x: 375, y: 95), CGPoint(x: 332, y: 228)])
                blob(c, m([(620, 190), (720, 230), (800, 330), (850, 470), (860, 620), (900, 760), (850, 900),
                           (790, 880), (800, 760), (740, 620), (720, 460), (680, 320)]))
                for flower in [(230, 420), (190, 600)] {
                    circle(c, CGFloat(flower.0), CGFloat(flower.1), 26)
                    circle(c, CGFloat(flower.0), CGFloat(flower.1), 10)
                }
            }, body: smooth(m(horseHead)), center: CGPoint(x: 440, y: 560), front: { c in
                polygon(c, [CGPoint(x: 455, y: 205), CGPoint(x: 440, y: 80), CGPoint(x: 390, y: 210)])
                blob(c, m([(560, 195), (470, 215), (430, 290), (500, 300), (585, 245)]))
                polygon(c, [CGPoint(x: 500, y: 215), CGPoint(x: 600, y: 40), CGPoint(x: 548, y: 238)])
                for t: CGFloat in [0.3, 0.55, 0.78] {
                    line(c, CGPoint(x: 500 + 100 * t, y: 215 - 175 * t), CGPoint(x: 548 + 52 * t, y: 238 - 198 * t))
                }
                oval(c, 545, 345, 30, 18, 35)
                circle(c, 545, 345, 8)
                oval(c, 732, 628, 20, 12, 60)
                curve(c, (745, 690), control: (710, 705), to: (670, 695))
            })
        case "giraffe":
            return PatternAnimal(behind: { c in
                for (x, top) in [(CGFloat(455), CGFloat(440)), (545, 560)] {
                    line(c, CGPoint(x: x, y: 200), CGPoint(x: top, y: 95))
                    circle(c, top, 85, 24)
                }
                oval(c, 330, 228, 72, 32, -20)
                oval(c, 670, 228, 72, 32, 20)
            }, body: smooth([(380, 960), (410, 660), (440, 420), (560, 420), (590, 660), (620, 960)]),
            center: CGPoint(x: 500, y: 700), front: { c in
                blob(c, [(370, 250), (500, 185), (630, 250), (640, 340), (590, 430), (530, 520), (470, 520), (410, 430), (360, 340)])
                oval(c, 500, 470, 75, 55, 0)
                circle(c, 475, 470, 10)
                circle(c, 525, 470, 10)
                eye(c, 430, 320, 22)
                eye(c, 570, 320, 22)
            })
        case "squirrel":
            return PatternAnimal(behind: { _ in },
                body: smooth([(560, 820), (720, 770), (830, 570), (800, 320), (660, 180), (545, 230), (600, 345), (690, 450), (650, 620), (560, 700)]),
                center: CGPoint(x: 690, y: 480), front: { c in
                blob(c, [(420, 520), (525, 500), (590, 620), (570, 790), (455, 840), (360, 790), (345, 640)])
                oval(c, 445, 690, 55, 95, 0)
                polygon(c, [CGPoint(x: 365, y: 335), CGPoint(x: 395, y: 235), CGPoint(x: 432, y: 335)])
                circle(c, 380, 420, 105)
                eye(c, 345, 400, 16)
                circle(c, 278, 435, 12)
                oval(c, 330, 560, 38, 25, -20)
                oval(c, 430, 835, 55, 25, 0)
                oval(c, 530, 835, 55, 25, 0)
            })
        case "koala":
            return PatternAnimal(behind: { c in
                for x: CGFloat in [295, 705] {
                    circle(c, x, 250, 115)
                    circle(c, x, 250, 65)
                }
            }, body: smooth([(500, 560), (665, 620), (715, 820), (500, 895), (285, 820), (335, 620)]),
            center: CGPoint(x: 500, y: 760), front: { c in
                circle(c, 500, 420, 205)
                oval(c, 500, 468, 55, 75, 0)
                eye(c, 420, 390, 18)
                eye(c, 580, 390, 18)
                oval(c, 360, 720, 50, 100, 20)
                oval(c, 640, 720, 50, 100, -20)
                oval(c, 400, 885, 70, 35, 0)
                oval(c, 600, 885, 70, 35, 0)
            })
        case "crab":
            return PatternAnimal(behind: { c in
                for side: CGFloat in [-1, 1] {
                    for k in 0..<3 {
                        let a = CGPoint(x: 500 + side * 200, y: 560 + CGFloat(k) * 50)
                        let b = CGPoint(x: 500 + side * 370, y: 620 + CGFloat(k) * 90)
                        polygon(c, [CGPoint(x: a.x, y: a.y - 14), CGPoint(x: b.x, y: b.y - 9),
                                    CGPoint(x: b.x, y: b.y + 9), CGPoint(x: a.x, y: a.y + 14)])
                    }
                    polygon(c, [CGPoint(x: 500 + side * 120, y: 470), CGPoint(x: 500 + side * 210, y: 350),
                                CGPoint(x: 500 + side * 240, y: 370), CGPoint(x: 500 + side * 160, y: 490)])
                    let claw: [(CGFloat, CGFloat)] = [(280, 250), (380, 230), (410, 330), (340, 380), (260, 340)]
                    blob(c, side < 0 ? claw : claw.map { (1000 - $0.0, $0.1) })
                    line(c, CGPoint(x: side < 0 ? 300 : 700, y: 300), CGPoint(x: side < 0 ? 380 : 620, y: 290))
                }
            }, body: smooth((0..<16).map { i -> (CGFloat, CGFloat) in
                let angle = CGFloat(i) * .pi / 8
                return (500 + cos(angle) * 230, 590 + sin(angle) * 145)
            }), center: CGPoint(x: 500, y: 600), front: { c in
                for x: CGFloat in [445, 555] {
                    line(c, CGPoint(x: x, y: 455), CGPoint(x: x - (x < 500 ? 10 : -10), y: 400))
                    eye(c, x - (x < 500 ? 10 : -10), 385, 24)
                }
                curve(c, (460, 520), control: (500, 545), to: (540, 520))
            })
        case "deer":
            return PatternAnimal(behind: { c in
                c.saveGState()
                c.setLineWidth(14)
                for side: CGFloat in [-1, 1] {
                    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: 500 + side * (500 - x), y: y) }
                    line(c, p(440, 285), p(380, 150))
                    line(c, p(380, 150), p(335, 85))
                    line(c, p(405, 200), p(465, 120))
                    line(c, p(370, 135), p(290, 140))
                }
                c.restoreGState()
                oval(c, 330, 335, 80, 35, -25)
                oval(c, 670, 335, 80, 35, 25)
            }, body: smooth([(500, 270), (605, 305), (650, 420), (600, 590), (535, 720), (465, 720), (400, 590), (350, 420), (395, 305)]),
            center: CGPoint(x: 500, y: 470), front: { c in
                oval(c, 500, 690, 45, 30, 0)
                for x: CGFloat in [430, 570] {
                    oval(c, x, 430, 30, 18, x < 500 ? 10 : -10)
                    circle(c, x, 430, 8)
                }
            })
        case "panda":
            return PatternAnimal(behind: { c in
                circle(c, 330, 170, 75)
                circle(c, 670, 170, 75)
            }, body: smooth([(500, 500), (700, 575), (765, 775), (645, 905), (355, 905), (235, 775), (300, 575)]),
            center: CGPoint(x: 500, y: 740), front: { c in
                oval(c, 330, 650, 60, 120, 25)
                oval(c, 670, 650, 60, 120, -25)
                oval(c, 380, 900, 80, 45, 0)
                oval(c, 620, 900, 80, 45, 0)
                circle(c, 500, 330, 190)
                oval(c, 425, 330, 48, 62, 30)
                oval(c, 575, 330, 48, 62, -30)
                circle(c, 430, 325, 16)
                circle(c, 570, 325, 16)
                oval(c, 500, 400, 28, 18, 0)
                curve(c, (470, 440), control: (500, 460), to: (530, 440))
            })
        case "parrot":
            return PatternAnimal(behind: { c in
                polygon(c, [CGPoint(x: 150, y: 820), CGPoint(x: 850, y: 820), CGPoint(x: 850, y: 860), CGPoint(x: 150, y: 860)])
                polygon(c, [CGPoint(x: 470, y: 780), CGPoint(x: 560, y: 780), CGPoint(x: 600, y: 955), CGPoint(x: 500, y: 955)])
                line(c, CGPoint(x: 515, y: 790), CGPoint(x: 550, y: 950))
            }, body: smooth([(430, 240), (545, 255), (605, 380), (625, 560), (585, 705), (525, 810), (470, 815), (452, 700), (420, 560), (400, 400)]),
            center: CGPoint(x: 520, y: 520), front: { c in
                blob(c, [(408, 262), (320, 285), (318, 350), (360, 362), (410, 330)])
                eye(c, 470, 300, 22)
                blob(c, [(525, 400), (615, 455), (610, 650), (530, 720), (490, 560)])
                oval(c, 470, 825, 30, 18, 0)
                oval(c, 540, 825, 30, 18, 0)
            })
        case "dinosaur":
            return PatternAnimal(behind: { c in
                for leg in [(330, 640), (450, 650), (600, 640), (690, 620)] {
                    let x = CGFloat(leg.0), y = CGFloat(leg.1)
                    polygon(c, [CGPoint(x: x, y: y), CGPoint(x: x + 65, y: y), CGPoint(x: x + 60, y: 805), CGPoint(x: x + 5, y: 805)])
                }
            }, body: smooth([(80, 665), (250, 565), (400, 475), (560, 452), (680, 470), (728, 405), (755, 265), (828, 215),
                             (885, 245), (862, 302), (800, 312), (775, 455), (762, 622), (622, 692), (420, 695), (250, 655)]),
            center: CGPoint(x: 450, y: 580), front: { c in
                eye(c, 838, 250, 13)
                curve(c, (880, 275), control: (860, 290), to: (835, 285))
            })
        default:
            return nil
        }
    }

    /// A horse's head and neck in profile, facing left: forehead, nose, muzzle, jaw, throat, neck.
    private static let horseHead: [(CGFloat, CGFloat)] = [
        (560, 200), (450, 250), (360, 380), (275, 545), (238, 640), (262, 705), (345, 715), (430, 650),
        (520, 590), (560, 660), (600, 800), (630, 920), (830, 920), (780, 720), (740, 470), (660, 250)
    ]
    private static let horseMane: [(CGFloat, CGFloat)] = [
        (620, 190), (720, 230), (800, 330), (850, 470), (860, 620), (900, 760), (850, 900),
        (790, 880), (800, 760), (740, 620), (720, 460), (680, 320)
    ]
}

/// A smooth closed shape through the given points (Catmull-Rom curves).
private func smooth(_ values: [(CGFloat, CGFloat)]) -> CGPath {
    let points = values.map { CGPoint(x: $0.0, y: $0.1) }
    let path = CGMutablePath()
    let n = points.count
    path.move(to: points[0])
    for i in 0..<n {
        let p0 = points[(i - 1 + n) % n], p1 = points[i], p2 = points[(i + 1) % n], p3 = points[(i + 2) % n]
        path.addCurve(to: p2,
                      control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                      control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
    }
    path.closeSubpath()
    return path
}

private func blob(_ context: CGContext, _ values: [(CGFloat, CGFloat)]) {
    context.addPath(smooth(values))
    context.drawPath(using: .fillStroke)
}

/// A fluffy outline with rounded bumps, for wool.
private func scallop(center: CGPoint, rx: CGFloat, ry: CGFloat, bumps: Int) -> CGPath {
    let path = CGMutablePath()
    func point(_ angle: CGFloat, _ scale: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * rx * scale, y: center.y + sin(angle) * ry * scale)
    }
    path.move(to: point(0, 1))
    for i in 0..<bumps {
        let a = CGFloat(i) * 2 * .pi / CGFloat(bumps), b = CGFloat(i + 1) * 2 * .pi / CGFloat(bumps)
        path.addQuadCurve(to: point(b, 1), control: point((a + b) / 2, 1.22))
    }
    path.closeSubpath()
    return path
}

private func oval(_ context: CGContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ degrees: CGFloat) {
    context.saveGState()
    context.translateBy(x: x, y: y)
    context.rotate(by: degrees * .pi / 180)
    context.addEllipse(in: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
    context.drawPath(using: .fillStroke)
    context.restoreGState()
}

private func eye(_ context: CGContext, _ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) {
    circle(context, x, y, radius)
    circle(context, x, y, radius * 0.45)
}

private func curve(_ context: CGContext, _ from: (CGFloat, CGFloat), control: (CGFloat, CGFloat), to: (CGFloat, CGFloat)) {
    context.move(to: CGPoint(x: from.0, y: from.1))
    context.addQuadCurve(to: CGPoint(x: to.0, y: to.1), control: CGPoint(x: control.0, y: control.1))
    context.strokePath()
}

private func ringStroke(_ context: CGContext, _ center: CGPoint, _ radius: CGFloat) {
    context.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    context.strokePath()
}

/// The mandala patterns inside a pattern animal's body; only lines, so the body stays white to color.
private func drawPattern(_ c: CGContext, style: Int, in box: CGRect, center: CGPoint, spacing s: CGFloat) {
    let reach = [CGPoint(x: box.minX, y: box.minY), CGPoint(x: box.maxX, y: box.minY),
                 CGPoint(x: box.minX, y: box.maxY), CGPoint(x: box.maxX, y: box.maxY)]
        .map { hypot($0.x - center.x, $0.y - center.y) }.max() ?? 0
    switch style % 6 {
    case 0:
        // Rosette: rings split into cells, each ring's cells offset like bricks, with a flower in the middle.
        let step = s * 0.75
        var r = step
        ringStroke(c, center, r)
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            ringStroke(c, CGPoint(x: center.x + cos(angle) * r * 0.5, y: center.y + sin(angle) * r * 0.5), r * 0.5)
        }
        var ring = 0
        while r < reach {
            let next = r + step
            ringStroke(c, center, next)
            let cells = max(6, Int(2 * .pi * (r + next) / 2 / s))
            for i in 0..<cells {
                let angle = (CGFloat(i) + (ring.isMultiple(of: 2) ? 0 : 0.5)) * 2 * .pi / CGFloat(cells)
                line(c, CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r),
                     CGPoint(x: center.x + cos(angle) * next, y: center.y + sin(angle) * next))
            }
            r = next
            ring += 1
        }
    case 1:
        // Scales: overlapping circles in offset rows.
        var row = 0
        var y = box.minY - s
        while y < box.maxY + s {
            var x = box.minX - s + (row.isMultiple(of: 2) ? 0 : s / 2)
            while x < box.maxX + s {
                ringStroke(c, CGPoint(x: x, y: y), s * 0.62)
                x += s
            }
            y += s * 0.85
            row += 1
        }
    case 2:
        // Waves crossed by straight lines, with a dot in every cell.
        let gap = s * 0.6
        var y = box.minY - gap
        var row = 0
        while y < box.maxY + gap {
            c.move(to: CGPoint(x: box.minX - s, y: y))
            var x = box.minX - s
            while x <= box.maxX + s {
                c.addLine(to: CGPoint(x: x, y: y + sin(x / s * 2 * .pi) * gap * 0.3))
                x += s / 8
            }
            c.strokePath()
            var dotX = box.minX + (row.isMultiple(of: 2) ? s / 2 : 0)
            while dotX < box.maxX {
                ringStroke(c, CGPoint(x: dotX + s / 2, y: y + gap / 2 + sin((dotX + s / 2) / s * 2 * .pi) * gap * 0.3), gap * 0.18)
                dotX += s
            }
            y += gap
            row += 1
        }
        var x = box.minX
        while x < box.maxX {
            line(c, CGPoint(x: x, y: box.minY), CGPoint(x: x, y: box.maxY))
            x += s
        }
    case 3:
        // Little flowers: a center with six round petals, in offset rows.
        var row = 0
        var y = box.minY
        while y < box.maxY + s {
            var x = box.minX + (row.isMultiple(of: 2) ? 0 : s / 2)
            while x < box.maxX + s {
                for i in 0..<6 {
                    let angle = CGFloat(i) * .pi / 3
                    ringStroke(c, CGPoint(x: x + cos(angle) * s * 0.27, y: y + sin(angle) * s * 0.27), s * 0.17)
                }
                ringStroke(c, CGPoint(x: x, y: y), s * 0.12)
                x += s
            }
            y += s * 0.87
            row += 1
        }
    case 4:
        // Zigzag bands with straight dividers.
        let gap = s * 0.55
        var y = box.minY
        while y < box.maxY + gap {
            c.move(to: CGPoint(x: box.minX - s, y: y))
            var x = box.minX - s
            var up = true
            while x <= box.maxX + s {
                x += s / 4
                c.addLine(to: CGPoint(x: x, y: y + (up ? -gap * 0.3 : gap * 0.3)))
                up.toggle()
            }
            c.strokePath()
            y += gap
        }
        var x = box.minX + s / 2
        while x < box.maxX {
            line(c, CGPoint(x: x, y: box.minY), CGPoint(x: x, y: box.maxY))
            x += s * 1.25
        }
    default:
        // Sun: rings joined by zigzag rays.
        let step = s * 0.8
        var r = step * 0.7
        ringStroke(c, center, r)
        while r < reach {
            let next = r + step
            ringStroke(c, center, next)
            let teeth = max(8, Int(2 * .pi * next / s))
            c.move(to: CGPoint(x: center.x + r, y: center.y))
            for i in 1...(teeth * 2) {
                let angle = CGFloat(i) * .pi / CGFloat(teeth)
                let radius = i.isMultiple(of: 2) ? r : next
                c.addLine(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
            }
            c.strokePath()
            r = next
        }
    }
}
