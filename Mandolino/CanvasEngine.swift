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

    static let palette: [PaintColor] = [
        (255, 89, 105, "Watermelon"), (239, 59, 68, "Red"),
        (255, 139, 66, "Orange"), (255, 189, 69, "Mango"),
        (255, 222, 85, "Sunshine"), (190, 222, 80, "Lime"),
        (91, 192, 116, "Grass"), (26, 151, 121, "Emerald"),
        (61, 203, 191, "Mint"), (53, 179, 217, "Sky"),
        (68, 124, 221, "Ocean"), (67, 76, 161, "Midnight"),
        (137, 101, 212, "Violet"), (192, 137, 231, "Lavender"),
        (238, 109, 178, "Pink"), (255, 176, 204, "Rose"),
        (173, 113, 76, "Cocoa"), (221, 179, 135, "Sand"),
        (117, 130, 145, "Slate"), (255, 255, 255, "Snow")
    ].enumerated().map {
        PaintColor(id: $0.offset, name: $0.element.3, red: UInt8($0.element.0),
                   green: UInt8($0.element.1), blue: UInt8($0.element.2))
    }

    static func mix(_ a: PaintColor, _ b: PaintColor) -> PaintColor {
        var ah: CGFloat = 0, asat: CGFloat = 0, av: CGFloat = 0
        var bh: CGFloat = 0, bsat: CGFloat = 0, bv: CGFloat = 0
        a.uiColor.getHue(&ah, saturation: &asat, brightness: &av, alpha: nil)
        b.uiColor.getHue(&bh, saturation: &bsat, brightness: &bv, alpha: nil)
        let rgbWheel: [CGFloat] = [0, 60, 120, 240, 360]
        let paintWheel: [CGFloat] = [0, 120, 180, 240, 360]
        func interpolate(_ value: CGFloat, from: [CGFloat], to: [CGFloat]) -> CGFloat {
            for i in 0..<(from.count - 1) where value <= from[i + 1] {
                return to[i] + (value - from[i]) / (from[i + 1] - from[i]) * (to[i + 1] - to[i])
            }
            return to.last!
        }
        let color: UIColor
        if asat < 0.05 || bsat < 0.05 {
            color = UIColor(red: CGFloat(Int(a.red) + Int(b.red)) / 510,
                            green: CGFloat(Int(a.green) + Int(b.green)) / 510,
                            blue: CGFloat(Int(a.blue) + Int(b.blue)) / 510, alpha: 1)
        } else {
            // A red-yellow-blue wheel makes familiar paint mixtures: yellow + blue becomes green.
            let aa = interpolate(ah * 360, from: rgbWheel, to: paintWheel) * .pi / 180
            let ba = interpolate(bh * 360, from: rgbWheel, to: paintWheel) * .pi / 180
            let x = (cos(aa) + cos(ba)) / 2, y = (sin(aa) + sin(ba)) / 2
            let strength = hypot(x, y)
            if strength < 0.12 {
                color = UIColor(red: 0.55, green: 0.40, blue: 0.25, alpha: 1)
            } else {
                var angle = atan2(y, x) * 180 / .pi
                if angle < 0 { angle += 360 }
                let hue = interpolate(angle, from: paintWheel, to: rgbWheel) / 360
                color = UIColor(hue: hue, saturation: (asat + bsat) / 2 * (0.65 + 0.35 * strength),
                                brightness: (av + bv) / 2, alpha: 1)
            }
        }
        var r: CGFloat = 0, g: CGFloat = 0, blue: CGFloat = 0
        color.getRed(&r, green: &g, blue: &blue, alpha: nil)
        return PaintColor(id: 100, name: "Mixed color", red: UInt8((r * 255).rounded()),
                          green: UInt8((g * 255).rounded()), blue: UInt8((blue * 255).rounded()))
    }
}

enum DrawingTool: String, CaseIterable, Identifiable {
    case fill, pencil, circle, square, triangle, eraser
    var id: String { rawValue }
    var title: String { L.text(rawValue.capitalized) }
    var isPaintTool: Bool { self == .fill || self == .eraser }
    var symbol: String {
        switch self {
        case .fill: return "drop.fill"
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
    private var undoStack: [CanvasSnapshot] = []
    private var redoStack: [CanvasSnapshot] = []
    private var strokeBase: CanvasSnapshot?
    private var saveTask: Task<Void, Never>?
    private var dirty = false

    init(template: MandalaTemplate?, size: Int = CanvasEngine.resolution, restore: Bool = true) {
        self.template = template
        self.documentID = template?.id ?? "free-draw"
        self.size = size
        lines = [UInt8](repeating: 255, count: size * size)
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
        paint = Array(state.paint)
        glitterMask = state.glitter.map(Array.init) ?? [UInt8](repeating: 0, count: size * size)
    }

    private func withLineContext(_ draw: (CGContext) -> Void) {
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
    }

    private func checkpoint(_ state: CanvasSnapshot? = nil) {
        undoStack.append(state ?? snapshot)
        if undoStack.count > 12 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    @discardableResult
    func fill(at point: CGPoint, color: PaintColor, glitter: Bool) -> Bool {
        guard point.x >= 0, point.y >= 0, point.x < 1, point.y < 1 else { return false }
        let x = Int(point.x * CGFloat(size)), y = Int(point.y * CGFloat(size))
        let seed = y * size + x
        guard lines[seed] >= 200 else {
            hint = "Tap inside a space, not on its black outline."
            return false
        }
        checkpoint()
        var visited = [UInt8](repeating: 0, count: size * size)
        var queue = [seed]
        visited[seed] = 1
        var cursor = 0
        // Connectivity comes from outlines, not paint: colored and glitter regions remain recolorable.
        while cursor < queue.count {
            let index = queue[cursor]
            cursor += 1
            let px = index % size, py = index / size
            var r = color.red, g = color.green, b = color.blue
            if glitter {
                let grain = Int(Self.noise(x: px, y: py) & 255)
                if grain < 18 {
                    r = 255; g = 255; b = 255
                } else if grain < 110 {
                    let highlight = Double(grain - 18) / 92 * 0.8
                    r = UInt8(Double(r) + (255 - Double(r)) * highlight)
                    g = UInt8(Double(g) + (255 - Double(g)) * highlight)
                    b = UInt8(Double(b) + (255 - Double(b)) * highlight)
                } else if grain > 130 {
                    let shade = 0.48 + Double(grain - 130) / 125 * 0.47
                    r = UInt8(Double(r) * shade)
                    g = UInt8(Double(g) * shade)
                    b = UInt8(Double(b) * shade)
                }
            }
            glitterMask[index] = glitter ? 1 : 0
            let offset = index * 4
            paint[offset] = r; paint[offset + 1] = g; paint[offset + 2] = b
            paint[offset + 3] = 255
            if px > 0 { enqueue(index - 1, visited: &visited, queue: &queue) }
            if px + 1 < size { enqueue(index + 1, visited: &visited, queue: &queue) }
            if py > 0 { enqueue(index - size, visited: &visited, queue: &queue) }
            if py + 1 < size { enqueue(index + size, visited: &visited, queue: &queue) }
        }
        hint = glitter ? "A little sparkle! Tap another space to keep coloring." : "Lovely! Keep adding your colors."
        changed()
        return true
    }

    private func enqueue(_ index: Int, visited: inout [UInt8], queue: inout [Int]) {
        if visited[index] == 0 && lines[index] >= 200 {
            visited[index] = 1
            queue.append(index)
        }
    }

    private static func noise(x: Int, y: Int) -> UInt32 {
        var value = UInt32(truncatingIfNeeded: x) &* 374_761_393
            &+ UInt32(truncatingIfNeeded: y) &* 668_265_263
        value = (value ^ (value >> 13)) &* 1_274_126_177
        return value ^ (value >> 16)
    }

    func beginStroke() {
        strokeBase = snapshot
    }

    func draw(from start: CGPoint, to end: CGPoint, tool: DrawingTool, width: CGFloat) {
        guard template == nil, !tool.isPaintTool else { return }
        if tool != .pencil, let strokeBase { apply(strokeBase) }
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
            case .fill, .eraser: break
            }
        }
        refresh()
    }

    func endStroke() {
        guard let strokeBase else { return }
        self.strokeBase = nil
        guard Data(lines) != strokeBase.lines else { return }
        checkpoint(strokeBase)
        hint = "Close your lines, then use Fill to color inside."
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
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 600_000_000)
            } catch { return }
            self?.save()
        }
    }

    func save() {
        guard dirty else { return }
        do {
            try JSONEncoder().encode(snapshot).write(to: documentURL(), options: .atomic)
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
        let lineData = Data(lines)
        guard let provider = CGDataProvider(data: lineData as CFData),
              let outline = CGImage(width: size, height: size, bitsPerComponent: 8,
                                    bitsPerPixel: 8, bytesPerRow: size,
                                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: [],
                                    provider: provider, decode: nil, shouldInterpolate: false,
                                    intent: .defaultIntent) else {
            preconditionFailure("Cannot render drawing")
        }
        composite.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: size, height: size,
                                          bitsPerComponent: 8, bytesPerRow: size * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                preconditionFailure("Cannot allocate color context")
            }
            context.setBlendMode(.multiply)
            context.draw(outline, in: CGRect(x: 0, y: 0, width: size, height: size))
            guard let result = context.makeImage() else { preconditionFailure("Cannot render drawing") }
            image = UIImage(cgImage: result)
        }
        undoCount = undoStack.count
        redoCount = redoStack.count
    }
}
