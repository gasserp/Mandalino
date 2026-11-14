import UIKit
import Combine

struct PaintColor: Identifiable {
    let id: Int
    let name: String
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var uiColor: UIColor {
        UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255,
                blue: CGFloat(blue) / 255, alpha: 1)
    }

    private static let paletteValues: [(UInt8, UInt8, UInt8, String)] = [
        (255, 89, 105, "Watermelon"), (239, 59, 68, "Red"),
        (255, 139, 66, "Orange"), (255, 189, 69, "Mango"),
        (255, 222, 85, "Sunshine"), (190, 222, 80, "Lime"),
        (91, 192, 116, "Grass"), (26, 151, 121, "Emerald"),
        (61, 203, 191, "Mint"), (53, 179, 217, "Sky"),
        (68, 124, 221, "Ocean"), (67, 76, 161, "Midnight"),
        (137, 101, 212, "Violet"), (192, 137, 231, "Lavender"),
        (238, 109, 178, "Pink"), (255, 176, 204, "Rose"),
        (173, 113, 76, "Cocoa"), (221, 179, 135, "Sand"),
        (117, 130, 145, "Slate"), (255, 255, 255, "Snow"),
        (24, 24, 32, "Black"), (122, 29, 53, "Burgundy"),
        (255, 112, 115, "Coral"), (255, 206, 179, "Peach"),
        (255, 239, 166, "Butter"), (181, 137, 37, "Gold"),
        (125, 143, 45, "Olive"), (30, 91, 65, "Forest"),
        (178, 235, 195, "Seafoam"), (0, 115, 133, "Teal"),
        (28, 220, 227, "Turquoise"), (169, 221, 255, "Ice"),
        (30, 51, 107, "Navy"), (95, 57, 155, "Plum"),
        (210, 52, 157, "Magenta"), (249, 200, 235, "Blush"),
        (96, 57, 38, "Chocolate"), (191, 156, 118, "Caramel"),
        (192, 200, 210, "Silver"), (255, 248, 229, "Ivory")
    ]
    static let palette: [PaintColor] = paletteValues.enumerated().map {
        PaintColor(id: $0.offset, name: $0.element.3, red: $0.element.0,
                   green: $0.element.1, blue: $0.element.2)
    }

    static func mix(_ a: PaintColor, _ b: PaintColor) -> PaintColor {
        mix([(a, 1), (b, 1)])
    }

    static func mix(_ ingredients: [(color: PaintColor, amount: Double)]) -> PaintColor {
        precondition(!ingredients.isEmpty && ingredients.allSatisfy { $0.amount.isFinite && $0.amount > 0 },
                     "A mixture needs colors with positive amounts")
        let total = ingredients.reduce(0) { $0 + $1.amount }
        precondition(total.isFinite, "Mixture amounts must have a finite total")
        if ingredients.allSatisfy({
            $0.color.red == ingredients[0].color.red &&
            $0.color.green == ingredients[0].color.green &&
            $0.color.blue == ingredients[0].color.blue
        }) {
            let first = ingredients[0].color
            return PaintColor(id: 100, name: "Mixed color", red: first.red, green: first.green, blue: first.blue)
        }
        let rgbWheel: [CGFloat] = [0, 60, 120, 240, 360]
        let paintWheel: [CGFloat] = [0, 120, 180, 240, 360]
        func interpolate(_ value: CGFloat, from: [CGFloat], to: [CGFloat]) -> CGFloat {
            for i in 0..<(from.count - 1) where value <= from[i + 1] {
                return to[i] + (value - from[i]) / (from[i + 1] - from[i]) * (to[i + 1] - to[i])
            }
            return to.last!
        }
        var x: CGFloat = 0, y: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        var hasNeutral = false
        for ingredient in ingredients {
            let weight = CGFloat(ingredient.amount / total)
            var hue: CGFloat = 0, sat: CGFloat = 0, value: CGFloat = 0
            ingredient.color.uiColor.getHue(&hue, saturation: &sat, brightness: &value, alpha: nil)
            let angle = interpolate(hue * 360, from: rgbWheel, to: paintWheel) * .pi / 180
            x += cos(angle) * weight
            y += sin(angle) * weight
            saturation += sat * weight
            brightness += value * weight
            red += CGFloat(ingredient.color.red) / 255 * weight
            green += CGFloat(ingredient.color.green) / 255 * weight
            blue += CGFloat(ingredient.color.blue) / 255 * weight
            hasNeutral = hasNeutral || sat < 0.05
        }
        let color: UIColor
        if hasNeutral {
            color = UIColor(red: red, green: green, blue: blue, alpha: 1)
        } else {
            // A red-yellow-blue wheel makes familiar paint mixtures: yellow + blue becomes green.
            let strength = hypot(x, y)
            if strength < 0.12 {
                color = UIColor(red: 0.55, green: 0.40, blue: 0.25, alpha: 1)
            } else {
                var angle = atan2(y, x) * 180 / .pi
                if angle < 0 { angle += 360 }
                let hue = interpolate(angle, from: paintWheel, to: rgbWheel) / 360
                color = UIColor(hue: hue, saturation: saturation * (0.65 + 0.35 * strength),
                                brightness: brightness, alpha: 1)
            }
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        return PaintColor(id: 100, name: "Mixed color", red: UInt8((r * 255).rounded()),
                          green: UInt8((g * 255).rounded()), blue: UInt8((b * 255).rounded()))
    }
}

enum GlitterStyle: UInt8, CaseIterable, Identifiable {
    case none = 0, fine, diamond, ruby, emerald, amethyst
    var id: UInt8 { rawValue }
    var title: String {
        switch self {
        case .none: return L.text("No glitter")
        case .fine: return L.text("Fine glitter")
        case .diamond: return L.text("Diamond")
        case .ruby: return L.text("Ruby")
        case .emerald: return L.text("Emerald")
        case .amethyst: return L.text("Amethyst")
        }
    }
}

enum PaintEffect: String, CaseIterable, Identifiable {
    case solid, gradient, stripes, dots, checkerboard, chevron
    var id: String { rawValue }
    var title: String { L.text(rawValue.capitalized) }
}

enum GradientDirection: String, CaseIterable, Identifiable {
    case horizontal, vertical, diagonal
    var id: String { rawValue }
    var title: String { L.text(rawValue.capitalized) }
}

struct PaintOptions {
    var effect: PaintEffect = .solid
    var secondColor = PaintColor.palette[19]
    var direction: GradientDirection = .horizontal

    func sample(color: PaintColor, x: Int, y: Int, size: Int, bounds: CGRect) -> (UInt8, UInt8, UInt8) {
        if effect == .solid { return (color.red, color.green, color.blue) }
        let amount: Double
        let px = x * 1000 / size, py = y * 1000 / size
        switch effect {
        case .solid: amount = 0
        case .gradient:
            let tx = (Double(x) - bounds.minX) / max(bounds.width - 1, 1)
            let ty = (Double(y) - bounds.minY) / max(bounds.height - 1, 1)
            switch direction {
            case .horizontal: amount = tx
            case .vertical: amount = ty
            case .diagonal: amount = (tx + ty) / 2
            }
        case .stripes: amount = (px + py) / 18 % 2 == 0 ? 0 : 1
        case .dots:
            let dx = px % 36 - 18, dy = py % 36 - 18
            amount = dx * dx + dy * dy < 64 ? 1 : 0
        case .checkerboard: amount = (px / 24 + py / 24) % 2 == 0 ? 0 : 1
        case .chevron: amount = (py + abs(px % 72 - 36)) / 18 % 2 == 0 ? 0 : 1
        }
        let t = min(max(amount, 0), 1)
        func channel(_ a: UInt8, _ b: UInt8) -> UInt8 {
            UInt8((Double(a) + (Double(b) - Double(a)) * t).rounded())
        }
        return (channel(color.red, secondColor.red), channel(color.green, secondColor.green),
                channel(color.blue, secondColor.blue))
    }
}

enum DrawingTool: String, CaseIterable, Identifiable {
    case fill, brush, pencil, circle, square, triangle, eraser
    var id: String { rawValue }
    var title: String { L.text(rawValue.capitalized) }
    var isPaintTool: Bool { self == .fill || self == .eraser }
    var symbol: String {
        switch self {
        case .fill: return "drop.fill"
        case .brush: return "paintbrush.pointed.fill"
        case .pencil: return "pencil.tip"
        case .circle: return "circle"
        case .square: return "square"
        case .triangle: return "triangle"
        case .eraser: return "eraser.fill"
        }
    }
}

struct CanvasSnapshot: Codable {
    let size: Int
    let lines: Data
    let paint: Data
    let glitter: Data?
}

enum CanvasStorageError: LocalizedError {
    case invalidDrawing
    var errorDescription: String? { L.text("This saved drawing could not be read. The original page is still available.") }
}

struct PageProgress: Equatable {
    let done: Int
    let total: Int
    var finished: Bool { total > 0 && done >= total }
}

/// The spaces of a coloring page that are big enough to color, found once from its outline.
/// Spaces touching the page edge (the background) and specks too small to tap don't count.
final class SpaceMap {
    let labels: [Int32]
    let sizes: [Int]

    init(lines: [UInt8], size: Int) {
        let count = size * size
        var labels = [Int32](repeating: -1, count: count)
        var sizes: [Int] = []
        var seen = [Bool](repeating: false, count: count)
        var queue = [Int32](repeating: 0, count: count)
        let minimum = max(1, count / 5000)
        lines.withUnsafeBufferPointer { line in
            seen.withUnsafeMutableBufferPointer { seen in
                queue.withUnsafeMutableBufferPointer { q in
                    labels.withUnsafeMutableBufferPointer { label in
                        for seed in 0..<count where !seen[seed] && line[seed] >= 200 {
                            q[0] = Int32(seed); seen[seed] = true
                            var found = 1, cursor = 0, touchesEdge = false
                            while cursor < found {
                                let index = Int(q[cursor]); cursor += 1
                                let x = index % size, y = index / size
                                if x == 0 || y == 0 || x == size - 1 || y == size - 1 { touchesEdge = true }
                                for (valid, next) in [(x > 0, index - 1), (x + 1 < size, index + 1),
                                                      (y > 0, index - size), (y + 1 < size, index + size)]
                                    where valid && !seen[next] && line[next] >= 200 {
                                    seen[next] = true; q[found] = Int32(next); found += 1
                                }
                            }
                            guard !touchesEdge && found >= minimum else { continue }
                            let number = Int32(sizes.count)
                            for i in 0..<found { label[Int(q[i])] = number }
                            sizes.append(found)
                        }
                    }
                }
            }
        }
        self.labels = labels
        self.sizes = sizes
    }

    /// A space counts as colored once a tenth of it is not white, so dotted patterns on white and
    /// a brush stroke through it count too, while white paint (like erasing) does not.
    func progress(paint: [UInt8]) -> PageProgress {
        var colored = [Int](repeating: 0, count: sizes.count)
        paint.withUnsafeBufferPointer { p in
            labels.withUnsafeBufferPointer { l in
                for i in 0..<l.count where l[i] >= 0 {
                    let o = i * 4
                    if p[o] != 255 || p[o + 1] != 255 || p[o + 2] != 255 { colored[Int(l[i])] += 1 }
                }
            }
        }
        return PageProgress(done: zip(colored, sizes).filter { $0 * 10 >= $1 }.count, total: sizes.count)
    }
}

final class CanvasEngine: ObservableObject {
    static let resolution = 1000
    let size: Int
    let documentID: String
    let template: MandalaTemplate?
    // Not @Published: strokes replace it every frame, and re-rendering the whole editor each time
    // made the brush lag. The canvas view receives it through onRender instead.
    private(set) var image: UIImage = UIImage()
    var onRender: (() -> Void)?
    @Published private(set) var undoCount = 0
    @Published private(set) var redoCount = 0
    @Published var errorMessage: String?
    @Published var hint = "Choose a color, then tap a white space."
    /// How many of the page's spaces are colored; nil until counted, and always nil for own drawings.
    @Published private(set) var progress: PageProgress?
    private var spaceMap: SpaceMap?
    private static let progressQueue = DispatchQueue(label: "Mandolino.progress", qos: .userInitiated)
    private(set) var lines: [UInt8]
    private(set) var paint: [UInt8]
    private(set) var glitterMask: [UInt8]
    private(set) var sparklePoints: [CGPoint] = []
    private var originalLines: [UInt8]
    private var outlineImage: CGImage?
    private var undoStack: [CanvasSnapshot] = []
    private var redoStack: [CanvasSnapshot] = []
    private var strokeBase: CanvasSnapshot?
    private var saveTask: Task<Void, Never>?
    // Shared by all pages so the old-format conversion and a page's own saves never interleave.
    private static let saveQueue = DispatchQueue(label: "Mandolino.drawing-save", qos: .utility)
    private var revision = 0
    private var dirty = false

    /// Own drawings have no template; each one is told apart by its `documentID` (see `ownDrawingIDs`).
    init(template: MandalaTemplate?, documentID: String? = nil, size: Int = CanvasEngine.resolution,
         restore: Bool = true) {
        self.template = template
        self.documentID = documentID ?? template?.id ?? Self.firstOwnDrawingID
        self.size = size
        lines = [UInt8](repeating: 255, count: size * size)
        originalLines = lines
        paint = [UInt8](repeating: 255, count: size * size * 4)
        glitterMask = [UInt8](repeating: 0, count: size * size)
        renderOriginal()
        if restore {
            do {
                let url = try Self.fileURL(self.documentID, "mandolino")
                let legacyURL = try Self.fileURL(self.documentID, "json")
                let saved: CanvasSnapshot?
                if FileManager.default.fileExists(atPath: url.path) {
                    saved = try Self.decode(Data(contentsOf: url))
                } else if FileManager.default.fileExists(atPath: legacyURL.path) {
                    saved = try JSONDecoder().decode(CanvasSnapshot.self, from: Data(contentsOf: legacyURL))
                } else {
                    saved = nil
                }
                if let saved {
                    guard saved.size == size, saved.lines.count == size * size,
                          saved.paint.count == size * size * 4,
                          saved.glitter == nil || saved.glitter?.count == size * size else {
                        throw CanvasStorageError.invalidDrawing
                    }
                    apply(saved)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        refresh()
    }

    private var snapshot: CanvasSnapshot {
        CanvasSnapshot(size: size, lines: Data(lines), paint: Data(paint), glitter: Data(glitterMask))
    }

    private func apply(_ state: CanvasSnapshot) {
        lines = Array(state.lines)
        outlineImage = nil
        paint = Array(state.paint)
        glitterMask = state.glitter.map(Array.init) ?? [UInt8](repeating: 0, count: size * size)
    }

    private func withLineContext(_ draw: (CGContext) -> Void) {
        outlineImage = nil
        lines.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: size, height: size,
                                          bitsPerComponent: 8, bytesPerRow: size,
                                          space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                preconditionFailure("Cannot allocate drawing context")
            }
            context.translateBy(x: 0, y: CGFloat(size))
            context.scaleBy(x: 1, y: -1)
            draw(context)
        }
    }

    private func renderOriginal() {
        lines = [UInt8](repeating: 255, count: size * size)
        if let template {
            withLineContext { template.draw(in: $0, size: size) }
        }
        originalLines = lines
        outlineImage = nil
    }

    private func checkpoint(_ state: CanvasSnapshot? = nil) {
        undoStack.append(state ?? snapshot)
        if undoStack.count > 12 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    @discardableResult
    func fill(at point: CGPoint, color: PaintColor, glitter: Bool) -> Bool {
        fill(at: point, color: color, glitterStyle: glitter ? .fine : .none)
    }

    /// The kaleidoscope copies for mirror drawing: each of `symmetry` turns around the page's center,
    /// plus its mirror image. Off (0 or 1) is just the identity. `side` is the page width in the
    /// coordinates being transformed (1 for normalized points).
    static func symmetryTransforms(_ symmetry: Int, side: CGFloat) -> [CGAffineTransform] {
        guard symmetry > 1 else { return [.identity] }
        let center = side / 2
        return (0..<symmetry).flatMap { turn -> [CGAffineTransform] in
            let rotated = CGAffineTransform(translationX: center, y: center)
                .rotated(by: CGFloat(turn) * 2 * .pi / CGFloat(symmetry))
            return [rotated.translatedBy(x: -center, y: -center),
                    rotated.scaledBy(x: -1, y: 1).translatedBy(x: -center, y: -center)]
        }
    }

    @discardableResult
    func fill(at point: CGPoint, color: PaintColor, glitterStyle: GlitterStyle,
              options: PaintOptions = PaintOptions(), symmetry: Int = 0) -> Bool {
        guard point.x >= 0, point.y >= 0, point.x < 1, point.y < 1 else { return false }
        let x = Int(point.x * CGFloat(size)), y = Int(point.y * CGFloat(size))
        guard lines[y * size + x] >= 200 else {
            hint = "Tap inside a space, not on its black outline."
            return false
        }
        checkpoint()
        let size = self.size
        // With mirror drawing, the matching spaces around the circle are filled too, in the same undo step.
        let seeds = Self.symmetryTransforms(symmetry, side: 1).compactMap { transform -> Int? in
            let p = point.applying(transform)
            guard p.x >= 0, p.y >= 0, p.x < 1, p.y < 1 else { return nil }
            let seed = Int(p.y * CGFloat(size)) * size + Int(p.x * CGFloat(size))
            return lines[seed] >= 200 ? seed : nil
        }
        var queue = [Int32](repeating: 0, count: size * size)
        var visited = [Bool](repeating: false, count: size * size)
        for seed in seeds where !visited[seed] {
            var count = 0
            var minX = seed % size, maxX = minX, minY = seed / size, maxY = minY
            // Connectivity comes from outlines, not paint: colored and glitter regions remain recolorable.
            lines.withUnsafeBufferPointer { lineBuffer in
                visited.withUnsafeMutableBufferPointer { seen in
                    queue.withUnsafeMutableBufferPointer { q in
                        q[0] = Int32(seed); seen[seed] = true; count = 1
                        var cursor = 0
                        while cursor < count {
                            let index = Int(q[cursor]); cursor += 1
                            let px = index % size, py = index / size
                            if px < minX { minX = px } else if px > maxX { maxX = px }
                            if py < minY { minY = py } else if py > maxY { maxY = py }
                            var next = index - 1
                            if px > 0, !seen[next], lineBuffer[next] >= 200 {
                                seen[next] = true; q[count] = Int32(next); count += 1
                            }
                            next = index + 1
                            if px + 1 < size, !seen[next], lineBuffer[next] >= 200 {
                                seen[next] = true; q[count] = Int32(next); count += 1
                            }
                            next = index - size
                            if py > 0, !seen[next], lineBuffer[next] >= 200 {
                                seen[next] = true; q[count] = Int32(next); count += 1
                            }
                            next = index + size
                            if py + 1 < size, !seen[next], lineBuffer[next] >= 200 {
                                seen[next] = true; q[count] = Int32(next); count += 1
                            }
                        }
                    }
                }
            }
            let bounds = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
            let style = glitterStyle.rawValue
            paint.withUnsafeMutableBufferPointer { paintBuffer in
                glitterMask.withUnsafeMutableBufferPointer { mask in
                    for i in 0..<count {
                        let index = Int(queue[i])
                        let px = index % size, py = index / size
                        let base = options.sample(color: color, x: px, y: py, size: size, bounds: bounds)
                        let rgb = Self.texture(base, style: glitterStyle, x: px, y: py)
                        mask[index] = style
                        let offset = index * 4
                        paintBuffer[offset] = rgb.0; paintBuffer[offset + 1] = rgb.1
                        paintBuffer[offset + 2] = rgb.2; paintBuffer[offset + 3] = 255
                    }
                }
            }
        }
        hint = glitterStyle != .none ? "A little sparkle! Tap another space to keep coloring." : "Lovely! Keep adding your colors."
        changed()
        return true
    }

    private static let swatchCache = NSCache<NSString, UIImage>()

    /// A small sample of how a paint looks on the page, at the page's own scale, for the glitter and
    /// pattern buttons.
    static func swatch(color: PaintColor, glitter: GlitterStyle, options: PaintOptions) -> UIImage {
        let second = options.secondColor
        let key = "\(color.red),\(color.green),\(color.blue)|\(glitter.rawValue)|\(options.effect.rawValue)|\(second.red),\(second.green),\(second.blue)|\(options.direction.rawValue)" as NSString
        if let cached = swatchCache.object(forKey: key) { return cached }
        let side = 72
        var pixels = [UInt8](repeating: 255, count: side * side * 4)
        let bounds = CGRect(x: 0, y: 0, width: side, height: side)
        for y in 0..<side {
            for x in 0..<side {
                let base = options.sample(color: color, x: x, y: y, size: resolution, bounds: bounds)
                let rgb = texture(base, style: glitter, x: x, y: y)
                let offset = (y * side + x) * 4
                pixels[offset] = rgb.0; pixels[offset + 1] = rgb.1; pixels[offset + 2] = rgb.2
            }
        }
        let image = pixels.withUnsafeMutableBytes { bytes -> UIImage in
            guard let context = CGContext(data: bytes.baseAddress, width: side, height: side,
                                          bitsPerComponent: 8, bytesPerRow: side * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
                  let cgImage = context.makeImage() else {
                preconditionFailure("Cannot render swatch")
            }
            return UIImage(cgImage: cgImage)
        }
        swatchCache.setObject(image, forKey: key)
        return image
    }

    private static func noise(x: Int, y: Int) -> UInt32 {
        var value = UInt32(truncatingIfNeeded: x) &* 374_761_393
            &+ UInt32(truncatingIfNeeded: y) &* 668_265_263
        value = (value ^ (value >> 13)) &* 1_274_126_177
        return value ^ (value >> 16)
    }

    private static func texture(_ color: (UInt8, UInt8, UInt8), style: GlitterStyle,
                                x: Int, y: Int) -> (UInt8, UInt8, UInt8) {
        guard style != .none else { return color }
        var r = Double(color.0), g = Double(color.1), b = Double(color.2)
        let grain: Int
        if style == .fine {
            grain = Int(noise(x: x, y: y) & 255)
        } else {
            // Larger tiled facets distinguish crystals from fine-grained glitter at export resolution.
            let cell = Int(noise(x: x / 12, y: y / 12) & 255)
            grain = (cell + (x % 12 + y % 12 < 12 ? 48 : 160)) % 256
            switch style {
            case .ruby: r = r * 0.8 + 51; g = g * 0.8 + 8; b = b * 0.8 + 19
            case .emerald: r = r * 0.8 + 6; g = g * 0.8 + 44; b = b * 0.8 + 26
            case .amethyst: r = r * 0.8 + 36; g = g * 0.8 + 19; b = b * 0.8 + 51
            default: break
            }
        }
        if grain < 18 { return (255, 255, 255) }
        if grain < 110 {
            let highlight = Double(grain - 18) / 92 * 0.8
            r += (255 - r) * highlight; g += (255 - g) * highlight; b += (255 - b) * highlight
        } else if grain > 130 {
            let shade = 0.48 + Double(grain - 130) / 125 * 0.47
            r *= shade; g *= shade; b *= shade
        }
        return (UInt8(r), UInt8(g), UInt8(b))
    }

    func beginStroke() {
        strokeBase = snapshot
    }

    func draw(from start: CGPoint, to end: CGPoint, tool: DrawingTool, width: CGFloat,
              color: PaintColor = PaintColor.palette[0], glitterStyle: GlitterStyle = .none,
              options: PaintOptions = PaintOptions(), symmetry: Int = 0, render: Bool = true) {
        guard tool != .fill else { return }
        if tool == .brush || tool == .eraser {
            // A round-capped segment stays a round-capped segment when turned or mirrored.
            for transform in Self.symmetryTransforms(symmetry, side: 1) {
                drawBrush(from: start.applying(transform), to: end.applying(transform), width: width,
                          color: color, glitterStyle: glitterStyle, options: options, erasing: tool == .eraser)
            }
            if render { refresh() }
            return
        }
        if tool != .pencil, let strokeBase {
            lines = Array(strokeBase.lines)
            outlineImage = nil
        }
        withLineContext { context in
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(width * CGFloat(size) / 1000)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            let a = CGPoint(x: start.x * CGFloat(size), y: start.y * CGFloat(size))
            let b = CGPoint(x: end.x * CGFloat(size), y: end.y * CGFloat(size))
            let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
                              width: abs(a.x - b.x), height: abs(a.y - b.y))
            // Shapes are turned with the context, since a turned square is no longer an axis-aligned rect.
            for transform in Self.symmetryTransforms(symmetry, side: CGFloat(size)) {
                context.saveGState()
                context.concatenate(transform)
                switch tool {
                case .pencil:
                    context.move(to: a)
                    context.addLine(to: b)
                    context.strokePath()
                case .circle:
                    context.strokeEllipse(in: rect)
                case .square:
                    context.stroke(rect)
                case .triangle:
                    context.move(to: CGPoint(x: rect.midX, y: rect.minY))
                    context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                    context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                    context.closePath()
                    context.strokePath()
                case .fill, .eraser, .brush: break
                }
                context.restoreGState()
            }
        }
        if render { refresh() }
    }

    private func drawBrush(from start: CGPoint, to end: CGPoint, width: CGFloat,
                           color: PaintColor, glitterStyle: GlitterStyle, options: PaintOptions,
                           erasing: Bool) {
        let a = CGPoint(x: start.x * CGFloat(size), y: start.y * CGFloat(size))
        let b = CGPoint(x: end.x * CGFloat(size), y: end.y * CGFloat(size))
        let diameter = width * CGFloat(size) / 1000
        let radius = diameter / 2 + 1
        let minX = max(0, Int(floor(min(a.x, b.x) - radius)))
        let maxX = min(size - 1, Int(ceil(max(a.x, b.x) + radius)))
        let minY = max(0, Int(floor(min(a.y, b.y) - radius)))
        let maxY = min(size - 1, Int(ceil(max(a.y, b.y) + radius)))
        guard minX <= maxX, minY <= maxY else { return }
        let maskWidth = maxX - minX + 1, maskHeight = maxY - minY + 1
        var coverage = [UInt8](repeating: 0, count: maskWidth * maskHeight)
        coverage.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: maskWidth, height: maskHeight,
                                          bitsPerComponent: 8, bytesPerRow: maskWidth,
                                          space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                preconditionFailure("Cannot allocate brush context")
            }
            context.translateBy(x: 0, y: CGFloat(maskHeight))
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: -CGFloat(minX), y: -CGFloat(minY))
            context.setStrokeColor(UIColor.white.cgColor)
            context.setFillColor(UIColor.white.cgColor)
            context.setLineWidth(diameter)
            context.setLineCap(.round)
            context.move(to: a)
            context.addLine(to: b)
            context.strokePath()
            context.fillEllipse(in: CGRect(x: b.x - diameter / 2, y: b.y - diameter / 2,
                                           width: diameter, height: diameter))
        }
        let bounds = CGRect(x: 0, y: 0, width: size, height: size)
        if erasing { outlineImage = nil }
        for y in minY...maxY {
            for x in minX...maxX {
                let index = y * size + x
                let amount = coverage[(y - minY) * maskWidth + x - minX]
                guard amount > 0 else { continue }
                if erasing {
                    lines[index] = originalLines[index]
                    paint[index * 4] = 255; paint[index * 4 + 1] = 255; paint[index * 4 + 2] = 255
                    glitterMask[index] = 0
                    continue
                }
                let base = options.sample(color: color, x: x, y: y, size: size, bounds: bounds)
                let rgb = Self.texture(base, style: glitterStyle, x: x, y: y)
                let alpha = Double(amount) / 255
                func blend(_ value: UInt8, channel: Int) {
                    let offset = index * 4 + channel
                    paint[offset] = UInt8((Double(value) * alpha + Double(paint[offset]) * (1 - alpha)).rounded())
                }
                blend(rgb.0, channel: 0); blend(rgb.1, channel: 1); blend(rgb.2, channel: 2)
                glitterMask[index] = glitterStyle.rawValue
            }
        }
    }

    func renderStroke() {
        // Sparkles are rebuilt once the stroke ends instead of on every frame.
        refresh(sparkles: false)
    }

    func erase(at point: CGPoint, width: CGFloat, symmetry: Int = 0) {
        guard point.x >= 0, point.y >= 0, point.x < 1, point.y < 1 else { return }
        let index = Int(point.y * CGFloat(size)) * size + Int(point.x * CGFloat(size))
        if lines[index] < 200 {
            beginStroke()
            draw(from: point, to: point, tool: .eraser, width: width, symmetry: symmetry)
            endStroke()
        } else {
            fill(at: point, color: PaintColor.palette[19], glitterStyle: .none, symmetry: symmetry)
        }
    }

    func endStroke() {
        guard let strokeBase else { return }
        self.strokeBase = nil
        guard Data(lines) != strokeBase.lines || Data(paint) != strokeBase.paint ||
              Data(glitterMask) != strokeBase.glitter else { return }
        checkpoint(strokeBase)
        hint = Data(lines) != strokeBase.lines ? "Close your lines, then use Fill to color inside." :
            "Lovely! Keep adding your colors."
        changed()
    }

    func undo() {
        guard let state = undoStack.popLast() else { return }
        redoStack.append(snapshot)
        apply(state)
        changed()
    }

    func redo() {
        guard let state = redoStack.popLast() else { return }
        undoStack.append(snapshot)
        apply(state)
        changed()
    }

    func reset() {
        checkpoint()
        paint = [UInt8](repeating: 255, count: size * size * 4)
        glitterMask = [UInt8](repeating: 0, count: size * size)
        renderOriginal()
        changed()
    }

    /// Counts colored spaces in the background, so the editor never waits for it.
    func updateProgress() {
        guard template != nil else { return }
        let paint = self.paint, lines = originalLines, size = self.size, known = spaceMap
        Self.progressQueue.async { [weak self] in
            let map = known ?? SpaceMap(lines: lines, size: size)
            let progress = map.progress(paint: paint)
            DispatchQueue.main.async {
                guard let self else { return }
                self.spaceMap = map
                if self.progress != progress { self.progress = progress }
            }
        }
    }

    private func changed() {
        refresh()
        updateProgress()
        dirty = true
        revision += 1
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 600_000_000)
            } catch { return }
            self?.saveInBackground()
        }
    }

    private func saveInBackground() {
        guard dirty else { return }
        let state = snapshot, image = image, documentID = documentID, savingRevision = revision
        Self.saveQueue.async { [weak self] in
            let result = Result { try Self.write(state, image: image, documentID: documentID) }
            Task { @MainActor [weak self] in
                guard let self, self.revision == savingRevision, self.dirty else { return }
                switch result {
                case .success: self.dirty = false
                case .failure(let error):
                    self.errorMessage = "\(L.text("Your drawing could not be saved:")) \(error.localizedDescription)"
                }
            }
        }
    }

    func save() {
        guard dirty else { return }
        do {
            let state = snapshot, image = image
            try Self.saveQueue.sync { try Self.write(state, image: image, documentID: documentID) }
            dirty = false
        } catch {
            errorMessage = "\(L.text("Your drawing could not be saved:")) \(error.localizedDescription)"
        }
    }

    // A binary plist keeps the pixel buffers as raw bytes (JSON stored them as escaped base64,
    // about 14 MB a page), and LZFSE shrinks the mostly white buffers to a small file.
    private static func write(_ state: CanvasSnapshot, image: UIImage, documentID: String) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try (encoder.encode(state) as NSData).compressed(using: .lzfse) as Data
        // The gallery shows this thumbnail, or rebuilds the preview from the drawing when it is missing.
        // Removing it first means an app stopped mid-save never leaves an outdated thumbnail behind.
        let thumbnailURL = try fileURL(documentID, "png")
        try? FileManager.default.removeItem(at: thumbnailURL)
        try data.write(to: fileURL(documentID, "mandolino"), options: .atomic)
        try? FileManager.default.removeItem(at: fileURL(documentID, "json"))
        try? thumbnail(of: image).pngData()?.write(to: thumbnailURL, options: .atomic)
    }

    private static func decode(_ data: Data) throws -> CanvasSnapshot {
        try PropertyListDecoder().decode(CanvasSnapshot.self,
                                         from: (data as NSData).decompressed(using: .lzfse) as Data)
    }

    /// Rewrites drawings saved by older versions (about 14 MB of JSON each) in the compact format with a
    /// gallery thumbnail. Call it off the main thread. Each page is loaded and rewritten in one save-queue
    /// block, so a page being colored at the same time is never overwritten with an older version.
    static func convertLegacyDrawings() {
        guard let folder = try? drawingsFolder(),
              let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        else { return }
        for file in files where file.pathExtension == "json" {
            let id = file.deletingPathExtension().lastPathComponent
            let template = MandalaTemplate.all.first { $0.id == id }
            guard template != nil || id.hasPrefix(firstOwnDrawingID) else { continue }
            saveQueue.sync {
                let engine = CanvasEngine(template: template, documentID: id)
                // An unreadable drawing stays as it is, so opening the page still reports the problem.
                guard engine.errorMessage == nil else { return }
                try? write(engine.snapshot, image: engine.image, documentID: id)
            }
        }
    }

    private static func drawingsFolder() throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                appropriateFor: nil, create: true)
            .appendingPathComponent("Drawings", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func fileURL(_ documentID: String, _ pathExtension: String) throws -> URL {
        try drawingsFolder().appendingPathComponent(documentID).appendingPathExtension(pathExtension)
    }

    static func thumbnailURL(for documentID: String) throws -> URL {
        try fileURL(documentID, "png")
    }

    /// The first own drawing keeps the ID it always had, so drawings saved before there could be
    /// several still open; later ones get this prefix plus a unique suffix.
    static let firstOwnDrawingID = "free-draw"

    static func newOwnDrawingID() -> String {
        "\(firstOwnDrawingID)-\(UUID().uuidString)"
    }

    /// Saved own drawings, most recently changed first. A new drawing she leaves empty is never saved,
    /// so it does not show up here.
    static func ownDrawingIDs() -> [String] {
        guard let folder = try? drawingsFolder(),
              let files = try? FileManager.default.contentsOfDirectory(
                  at: folder, includingPropertiesForKeys: [.contentModificationDateKey]) else { return [] }
        var newest: [String: Date] = [:]
        for file in files where ["mandolino", "json"].contains(file.pathExtension) {
            let id = file.deletingPathExtension().lastPathComponent
            guard id.hasPrefix(firstOwnDrawingID) else { continue }
            let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            newest[id] = max(newest[id] ?? .distantPast, date ?? .distantPast)
        }
        return newest.sorted { $0.value > $1.value }.map(\.key)
    }

    static func preview(template: MandalaTemplate?, documentID: String? = nil, side: CGFloat = 300) throws -> UIImage {
        let engine = CanvasEngine(template: template, documentID: documentID)
        if let error = engine.errorMessage {
            throw NSError(domain: "CanvasPreview", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
        }
        return thumbnail(of: engine.image, side: side)
    }

    private static func thumbnail(of image: UIImage, side: CGFloat = 300) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    private func refresh(sparkles: Bool = true) {
        if sparkles {
            var candidates: [CGPoint] = []
            for y in stride(from: 12, to: size, by: max(8, size / 30)) {
                for x in stride(from: 12, to: size, by: max(8, size / 30)) {
                    let jitter = Int(Self.noise(x: x, y: y) % 13) - 6
                    let px = min(max(x + jitter, 0), size - 1)
                    let py = min(max(y - jitter, 0), size - 1)
                    let index = py * size + px
                    if glitterMask[index] != 0 && lines[index] >= 240 {
                        candidates.append(CGPoint(x: CGFloat(px) / CGFloat(size), y: CGFloat(py) / CGFloat(size)))
                    }
                }
            }
            if candidates.count > 140 {
                let step = Double(candidates.count) / 140
                sparklePoints = (0..<140).map { candidates[Int(Double($0) * step)] }
            } else {
                sparklePoints = candidates
            }
        }
        var composite = paint
        if outlineImage == nil {
            let lineData = Data(lines)
            guard let provider = CGDataProvider(data: lineData as CFData),
                  let outline = CGImage(width: size, height: size, bitsPerComponent: 8,
                                    bitsPerPixel: 8, bytesPerRow: size,
                                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: [],
                                    provider: provider, decode: nil, shouldInterpolate: false,
                                    intent: .defaultIntent) else {
                preconditionFailure("Cannot render drawing")
            }
            outlineImage = outline
        }
        composite.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: size, height: size,
                                          bitsPerComponent: 8, bytesPerRow: size * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                preconditionFailure("Cannot allocate color context")
            }
            context.setBlendMode(.multiply)
            context.draw(outlineImage!, in: CGRect(x: 0, y: 0, width: size, height: size))
            guard let result = context.makeImage() else { preconditionFailure("Cannot render drawing") }
            image = UIImage(cgImage: result)
        }
        // Assigning a @Published value re-renders the editor even when it is unchanged.
        if undoCount != undoStack.count { undoCount = undoStack.count }
        if redoCount != redoStack.count { redoCount = redoStack.count }
        onRender?()
    }
}
