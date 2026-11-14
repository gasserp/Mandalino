import XCTest
@testable import Mandolino

final class CanvasEngineTests: XCTestCase {
    private let red = PaintColor.palette[1]
    private let blue = PaintColor.palette[10]

    private func pixel(_ engine: CanvasEngine, _ x: CGFloat, _ y: CGFloat) -> [UInt8] {
        let index = (Int(y * CGFloat(engine.size)) * engine.size + Int(x * CGFloat(engine.size))) * 4
        return Array(engine.paint[index..<(index + 3)])
    }

    private func box(_ engine: CanvasEngine) {
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.2, y: 0.2), to: CGPoint(x: 0.8, y: 0.8),
                    tool: .square, width: 12)
        engine.endStroke()
    }

    func testFillStaysWithinBlackOutlineAndGlitterCanBeRecolored() {
        let engine = CanvasEngine(template: nil, size: 150, restore: false)
        box(engine)
        XCTAssertTrue(engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: true))
        XCTAssertEqual(pixel(engine, 0.1, 0.1), [255, 255, 255])
        let inside = stride(from: 35, to: 110, by: 1).map { pixel(engine, CGFloat($0) / 150, 0.5) }
        XCTAssertTrue(inside.contains([255, 255, 255]), "Glitter should contain visible sparkles")
        XCTAssertTrue(inside.contains([red.red, red.green, red.blue]))
        XCTAssertTrue(engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: blue, glitter: false))
        for sample in [CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.7, y: 0.7)] {
            XCTAssertEqual(pixel(engine, sample.x, sample.y), [blue.red, blue.green, blue.blue])
        }
        XCTAssertEqual(pixel(engine, 0.1, 0.1), [255, 255, 255])
        XCTAssertFalse(engine.fill(at: CGPoint(x: 0.2, y: 0.5), color: red, glitter: false))
    }

    func testUndoRedoAndResetPreserveBothLinesAndPaint() {
        let engine = CanvasEngine(template: nil, size: 120, restore: false)
        let blank = engine.lines
        box(engine)
        let outline = engine.lines
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: false)
        engine.undo()
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [255, 255, 255])
        XCTAssertEqual(engine.lines, outline)
        engine.undo()
        XCTAssertEqual(engine.lines, blank)
        engine.redo()
        engine.redo()
        XCTAssertEqual(engine.lines, outline)
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [red.red, red.green, red.blue])
        engine.reset()
        XCTAssertEqual(engine.lines, blank)
        engine.undo()
        XCTAssertEqual(engine.lines, outline)
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [red.red, red.green, red.blue])
    }

    func testRenderedImageAlignsPaintWithAnAsymmetricOutline() throws {
        let engine = CanvasEngine(template: nil, size: 160, restore: false)
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.1), to: CGPoint(x: 0.4, y: 0.4),
                    tool: .square, width: 12)
        engine.endStroke()
        engine.fill(at: CGPoint(x: 0.25, y: 0.25), color: red, glitter: false)
        let cgImage = try XCTUnwrap(engine.image.cgImage)
        let bytes = Array(try XCTUnwrap(cgImage.dataProvider?.data) as Data)
        let inside = (40 * cgImage.bytesPerRow) + 40 * 4
        let outside = (120 * cgImage.bytesPerRow) + 40 * 4
        let border = (40 * cgImage.bytesPerRow) + 16 * 4
        XCTAssertEqual(Array(bytes[inside..<(inside + 3)]), [red.red, red.green, red.blue])
        XCTAssertEqual(Array(bytes[outside..<(outside + 3)]), [255, 255, 255])
        XCTAssertLessThan(bytes[border], 30)
    }

    func testCirclesAndTrianglesAreClosedAndInvalidTapsDoNotAlterHistory() {
        for tool in [DrawingTool.circle, .triangle] {
            let engine = CanvasEngine(template: nil, size: 160, restore: false)
            engine.beginStroke()
            engine.draw(from: CGPoint(x: 0.2, y: 0.2), to: CGPoint(x: 0.8, y: 0.8),
                        tool: tool, width: 12)
            engine.endStroke()
            XCTAssertTrue(engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: blue, glitter: false))
            XCTAssertEqual(pixel(engine, 0.5, 0.5), [blue.red, blue.green, blue.blue])
            XCTAssertEqual(pixel(engine, 0.1, 0.1), [255, 255, 255])
            let undoCount = engine.undoCount
            XCTAssertFalse(engine.fill(at: CGPoint(x: -0.1, y: 0), color: red, glitter: false))
            XCTAssertEqual(engine.undoCount, undoCount)
        }
    }

    func testFreehandClosedLoopFillsAndShapePreviewLeavesNoGhostLines() {
        let engine = CanvasEngine(template: nil, size: 160, restore: false)
        engine.beginStroke()
        let corners = [CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.8, y: 0.2),
                       CGPoint(x: 0.8, y: 0.8), CGPoint(x: 0.2, y: 0.8),
                       CGPoint(x: 0.2, y: 0.2)]
        for pair in zip(corners, corners.dropFirst()) {
            engine.draw(from: pair.0, to: pair.1, tool: .pencil, width: 12)
        }
        engine.endStroke()
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: false)
        XCTAssertEqual(pixel(engine, 0.1, 0.1), [255, 255, 255])
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [red.red, red.green, red.blue])
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.35, y: 0.35), to: CGPoint(x: 0.65, y: 0.65),
                    tool: .circle, width: 6)
        engine.draw(from: CGPoint(x: 0.35, y: 0.35), to: CGPoint(x: 0.55, y: 0.55),
                    tool: .circle, width: 6)
        engine.endStroke()
        XCTAssertGreaterThan(engine.lines[80 * 160 + 104], 240)
    }

    func testSavedDrawingRestoresEditableLinesAndColors() throws {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                appropriateFor: nil, create: true)
            .appendingPathComponent("Drawings")
        let url = folder.appendingPathComponent("free-draw.json")
        let previous = FileManager.default.fileExists(atPath: url.path) ? try Data(contentsOf: url) : nil
        defer {
            if let previous { try? previous.write(to: url, options: .atomic) }
            else { try? FileManager.default.removeItem(at: url) }
        }
        let original = CanvasEngine(template: nil, restore: false)
        box(original)
        original.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: true)
        original.save()
        XCTAssertNil(original.errorMessage)
        let restored = CanvasEngine(template: nil)
        XCTAssertNil(restored.errorMessage)
        XCTAssertEqual(restored.lines, original.lines)
        XCTAssertEqual(restored.paint, original.paint)
        XCTAssertEqual(restored.glitterMask, original.glitterMask)
        restored.fill(at: CGPoint(x: 0.5, y: 0.5), color: blue, glitter: false)
        XCTAssertEqual(pixel(restored, 0.5, 0.5), [blue.red, blue.green, blue.blue])
    }

    func testCatalogHasLargeDistinctCollectionsAndEnclosedColorableRegions() {
        XCTAssertGreaterThanOrEqual(MandalaTemplate.all.count, 96)
        XCTAssertEqual(Set(MandalaTemplate.all.map(\.id)).count, MandalaTemplate.all.count)
        for level in Difficulty.allCases {
            XCTAssertGreaterThanOrEqual(MandalaTemplate.all.filter { $0.difficulty == level }.count, 24)
        }
        var outlines = Set<Data>()
        for template in MandalaTemplate.all {
            let engine = CanvasEngine(template: template, size: template.difficulty == .expert ? 600 : 300,
                                      restore: false)
            let regions = enclosedRegions(engine)
            let minimum = template.difficulty == .expert ? 150 : template.difficulty == .easy ? 6 : 15
            XCTAssertGreaterThanOrEqual(regions, minimum,
                                        "\(template.title) needs meaningful closed coloring spaces")
            XCTAssertTrue(outlines.insert(Data(engine.lines)).inserted,
                          "\(template.id) should have a distinct outline, not just a different name")
        }
    }

    func testErasingColorRemovesGlitterButPreservesLinesAndSupportsUndo() {
        let engine = CanvasEngine(template: nil, size: 150, restore: false)
        box(engine)
        let outlines = engine.lines
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: true)
        XCTAssertFalse(engine.sparklePoints.isEmpty)
        let texturedPaint = engine.paint
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: PaintColor.palette[19], glitter: false)
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [255, 255, 255])
        XCTAssertEqual(engine.lines, outlines)
        XCTAssertTrue(engine.glitterMask.allSatisfy { $0 == 0 })
        XCTAssertTrue(engine.sparklePoints.isEmpty)
        engine.undo()
        XCTAssertEqual(engine.paint, texturedPaint)
        XCTAssertFalse(engine.sparklePoints.isEmpty)
    }

    func testChildFriendlyPrimaryPaintMixtures() {
        let yellow = PaintColor.palette[4]
        let orange = PaintColor.mix(red, yellow)
        XCTAssertGreaterThan(orange.red, orange.green)
        XCTAssertGreaterThan(orange.green, orange.blue)
        let green = PaintColor.mix(blue, yellow)
        XCTAssertGreaterThan(green.green, green.red)
        XCTAssertGreaterThan(green.green, green.blue)
        let purple = PaintColor.mix(red, blue)
        XCTAssertGreaterThan(purple.red, purple.green)
        XCTAssertGreaterThan(purple.blue, purple.green)
        let reverse = PaintColor.mix(yellow, blue)
        XCTAssertEqual([green.red, green.green, green.blue], [reverse.red, reverse.green, reverse.blue])
        let pink = PaintColor.mix(red, PaintColor.palette[19])
        XCTAssertGreaterThan(pink.green, red.green)
        XCTAssertGreaterThan(pink.blue, red.blue)
    }

    private func enclosedRegions(_ engine: CanvasEngine) -> Int {
        let size = engine.size
        var seen = [Bool](repeating: false, count: size * size)
        var count = 0
        for seed in engine.lines.indices where !seen[seed] && engine.lines[seed] >= 200 {
            var queue = [seed], cursor = 0, touchesEdge = false
            seen[seed] = true
            while cursor < queue.count {
                let p = queue[cursor]
                cursor += 1
                let x = p % size, y = p / size
                if x == 0 || y == 0 || x == size - 1 || y == size - 1 { touchesEdge = true }
                let neighbors = [(x > 0, p - 1), (x < size - 1, p + 1),
                                 (y > 0, p - size), (y < size - 1, p + size)]
                for (valid, n) in neighbors where valid && !seen[n] && engine.lines[n] >= 200 {
                    seen[n] = true
                    queue.append(n)
                }
            }
            if !touchesEdge && queue.count > 35 { count += 1 }
        }
        return count
    }
}
