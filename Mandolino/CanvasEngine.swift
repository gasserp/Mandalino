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

final class CanvasEngine: ObservableObject {
    static let resolution = 1000
    let size: Int
    let documentID: String
    let template: MandalaTemplate?
    @Published private(set) var image: UIImage = UIImage()
    @Published private(set) var undoCount = 0
    @Published private(set) var redoCount = 0
    @Published var errorMessage: String?
    @Published var hint = "Choose a color, then tap a white space."
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
    private let saveQueue = DispatchQueue(label: "Mandolino.drawing-save", qos: .utility)
    private var revision = 0
    private var dirty = false

    init(template: MandalaTemplate?, size: Int = CanvasEngine.resolution, restore: Bool = true) {
        self.template = template
        self.documentID = template?.id ?? "free-draw"
        self.size = size
        lines = [UInt8](repeating: 255, count: size * size)
        originalLines = lines
        paint = [UInt8](repeating: 255, count: size * size * 4)
        glitterMask = [UInt8](repeating: 0, count: size * size)
        renderOriginal()
        if restore {
            do {
                let url = try documentURL()
                if FileManager.default.fileExists(atPath: url.path) {
                    let saved = try JSONDecoder().decode(CanvasSnapshot.self, from: Data(contentsOf: url))
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

    @discardableResult
    func fill(at point: CGPoint, color: PaintColor, glitterStyle: GlitterStyle,
              options: PaintOptions = PaintOptions()) -> Bool {
        guard point.x >= 0, point.y >= 0, point.x < 1, point.y < 1 else { return false }
        let x = Int(point.x * CGFloat(size)), y = Int(point.y * CGFloat(size))
        let seed = y * size + x
        guard lines[seed] >= 200 else {
            hint = "Tap inside a space, not on its black outline."
            return false
        }
        checkpoint()
        let size = self.size
        var queue = [Int32](repeating: 0, count: size * size)
        var count = 0
        var minX = x, maxX = x, minY = y, maxY = y
        // Connectivity comes from outlines, not paint: colored and glitter regions remain recolorable.
        lines.withUnsafeBufferPointer { lineBuffer in
            var visited = [Bool](repeating: false, count: size * size)
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
        hint = glitterStyle != .none ? "A little sparkle! Tap another space to keep coloring." : "Lovely! Keep adding your colors."
        changed()
        return true
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
              options: PaintOptions = PaintOptions(), render: Bool = true) {
        guard tool != .fill else { return }
        if tool == .brush || tool == .eraser {
            drawBrush(from: start, to: end, width: width, color: color, glitterStyle: glitterStyle,
                      options: options, erasing: tool == .eraser)
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
        refresh()
    }

    func erase(at point: CGPoint, width: CGFloat) {
        guard point.x >= 0, point.y >= 0, point.x < 1, point.y < 1 else { return }
        let index = Int(point.y * CGFloat(size)) * size + Int(point.x * CGFloat(size))
        if lines[index] < 200 {
            beginStroke()
            draw(from: point, to: point, tool: .eraser, width: width)
            endStroke()
        } else {
            fill(at: point, color: PaintColor.palette[19], glitterStyle: .none)
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

    private func changed() {
        refresh()
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
        do {
            let url = try documentURL()
            let state = snapshot, savingRevision = revision
            saveQueue.async { [weak self] in
                let result = Result { try JSONEncoder().encode(state).write(to: url, options: .atomic) }
                Task { @MainActor [weak self] in
                    guard let self, self.revision == savingRevision, self.dirty else { return }
                    switch result {
                    case .success: self.dirty = false
                    case .failure(let error):
                        self.errorMessage = "\(L.text("Your drawing could not be saved:")) \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            errorMessage = "\(L.text("Your drawing could not be saved:")) \(error.localizedDescription)"
        }
    }

    func save() {
        guard dirty else { return }
        do {
            let state = snapshot, url = try documentURL()
            try saveQueue.sync {
                try JSONEncoder().encode(state).write(to: url, options: .atomic)
            }
            dirty = false
        } catch {
            errorMessage = "\(L.text("Your drawing could not be saved:")) \(error.localizedDescription)"
        }
    }

    private func documentURL() throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                appropriateFor: nil, create: true)
            .appendingPathComponent("Drawings", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(documentID).appendingPathExtension("json")
    }

    static func preview(template: MandalaTemplate?, side: CGFloat = 300) throws -> UIImage {
        let engine = CanvasEngine(template: template)
        if let error = engine.errorMessage {
            throw NSError(domain: "CanvasPreview", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            engine.image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    private func refresh() {
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
        undoCount = undoStack.count
        redoCount = redoStack.count
    }
}
