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

    func testInteractivePaintingPerformance() {
        let engine = CanvasEngine(template: MandalaTemplate.all[0], restore: false)
        engine.beginStroke()
        let start = Date()
        for i in 0..<60 {
            engine.draw(from: CGPoint(x: 0.1 + Double(i) * 0.01, y: 0.15),
                        to: CGPoint(x: 0.11 + Double(i) * 0.01, y: 0.15),
                        tool: .brush, width: 36, color: blue, glitterStyle: .diamond)
        }
        let elapsed = Date().timeIntervalSince(start)
        print("PAINT_PERFORMANCE segment_ms=\(elapsed / 60 * 1000)")
        XCTAssertLessThan(elapsed / 60, 1.0 / 60, "Drawing and compositing should fit a 60 Hz frame")
        engine.endStroke()
        let fillStart = Date()
        engine.fill(at: CGPoint(x: 0.01, y: 0.01), color: red, glitterStyle: .diamond)
        let fillTime = Date().timeIntervalSince(fillStart)
        print("PAINT_PERFORMANCE fill_ms=\(fillTime * 1000)")
        XCTAssertLessThan(fillTime, 0.15, "Large textured fills should respond without a noticeable stall")
    }

    func testEraserRubsOutDrawnLinesAndBrushPaintWithoutRemovingTemplate() {
        let engine = CanvasEngine(template: MandalaTemplate.all[0], size: 200, restore: false)
        let original = engine.lines
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.15), to: CGPoint(x: 0.9, y: 0.15),
                    tool: .pencil, width: 12)
        engine.endStroke()
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.15), to: CGPoint(x: 0.9, y: 0.15),
                    tool: .brush, width: 36, color: red, glitterStyle: .ruby)
        engine.endStroke()
        let drawnLines = engine.lines, drawnPaint = engine.paint
        XCTAssertNotEqual(drawnLines, original)
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.05, y: 0.15), to: CGPoint(x: 0.95, y: 0.15),
                    tool: .eraser, width: 60)
        engine.endStroke()
        XCTAssertEqual(engine.lines, original)
        XCTAssertTrue(engine.paint.allSatisfy { $0 == 255 })
        XCTAssertTrue(engine.glitterMask.allSatisfy { $0 == 0 })
        engine.undo()
        XCTAssertEqual(engine.lines, drawnLines)
        XCTAssertEqual(engine.paint, drawnPaint)
        engine.redo()
        XCTAssertEqual(engine.lines, original)
        engine.beginStroke()
        engine.draw(from: .zero, to: CGPoint(x: 1, y: 1), tool: .eraser, width: 80)
        engine.endStroke()
        XCTAssertEqual(engine.lines, original, "The eraser must never change the original mandala")
    }

    func testTappingDrawnOutlineErasesLocallyAndReopensFillBoundary() {
        let engine = CanvasEngine(template: nil, size: 200, restore: false)
        box(engine)
        engine.erase(at: CGPoint(x: 0.2, y: 0.5), width: 36)
        XCTAssertEqual(engine.lines[100 * 200 + 40], 255)
        XCTAssertLessThan(engine.lines[40 * 200 + 100], 200)
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none)
        XCTAssertEqual(pixel(engine, 0.1, 0.1), [red.red, red.green, red.blue])
    }

    func testGradientsUseConfiguredEndpointsAndRegionBoundsInEveryDirection() {
        for direction in GradientDirection.allCases {
            let engine = CanvasEngine(template: nil, size: 200, restore: false)
            box(engine)
            let options = PaintOptions(effect: .gradient, secondColor: blue, direction: direction)
            engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none, options: options)
            let a = pixel(engine, 0.23, 0.23), b = pixel(engine, 0.77, 0.77)
            XCTAssertGreaterThan(a[0], b[0])
            XCTAssertLessThan(a[2], b[2])
            XCTAssertEqual(pixel(engine, 0.1, 0.1), [255, 255, 255])
            let horizontal = pixel(engine, 0.25, 0.5), vertical = pixel(engine, 0.5, 0.25)
            if direction == .horizontal { XCTAssertGreaterThan(horizontal[0], vertical[0]) }
            if direction == .vertical { XCTAssertGreaterThan(vertical[0], horizontal[0]) }
            let midpoint = pixel(engine, 0.5, 0.5)
            XCTAssertEqual(Int(midpoint[0]), (Int(red.red) + Int(blue.red)) / 2, accuracy: 3)
            engine.undo()
            XCTAssertEqual(pixel(engine, 0.5, 0.5), [255, 255, 255])
            engine.redo()
            XCTAssertEqual(pixel(engine, 0.5, 0.5), midpoint)
        }
    }

    func testPatternsAreDistinctClippedTwoColorAndWorkWithBrushAndGlitter() {
        let engine = CanvasEngine(template: nil, size: 200, restore: false)
        box(engine)
        var textures = Set<Data>()
        for effect in [PaintEffect.stripes, .dots, .checkerboard, .chevron] {
            let options = PaintOptions(effect: effect, secondColor: blue)
            engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none, options: options)
            XCTAssertTrue(textures.insert(Data(engine.paint)).inserted)
            let samples = (50..<150).flatMap { y in (50..<150).map { x in pixel(engine, CGFloat(x) / 200, CGFloat(y) / 200) } }
            XCTAssertTrue(samples.contains([red.red, red.green, red.blue]))
            XCTAssertTrue(samples.contains([blue.red, blue.green, blue.blue]))
            XCTAssertEqual(pixel(engine, 0.1, 0.9), [255, 255, 255])
            engine.beginStroke()
            engine.draw(from: CGPoint(x: 0.05, y: 0.1), to: CGPoint(x: 0.9, y: 0.1),
                        tool: .brush, width: 36, color: red, glitterStyle: .diamond, options: options)
            engine.endStroke()
            XCTAssertEqual(engine.glitterMask[20 * 200 + 100], GlitterStyle.diamond.rawValue)
        }
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
        let restore = try preserveSavedFiles(of: "free-draw")
        defer { restore() }
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

    func testSavedDrawingIsCompactAndWritesGalleryThumbnail() throws {
        let template = MandalaTemplate.all[0]
        let restore = try preserveSavedFiles(of: template.id)
        defer { restore() }
        let engine = CanvasEngine(template: template, restore: false)
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none)
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.15), to: CGPoint(x: 0.9, y: 0.15),
                    tool: .brush, width: 36, color: blue, glitterStyle: .diamond)
        engine.endStroke()
        engine.save()
        XCTAssertNil(engine.errorMessage)
        let saved = try Data(contentsOf: savedFileURL(template.id, "mandolino"))
        print("SAVE_SIZE bytes=\(saved.count)")
        XCTAssertLessThan(saved.count, 500_000, "The old JSON format needed about 14 MB a page")
        let thumbnail = try XCTUnwrap(UIImage(contentsOfFile: CanvasEngine.thumbnailURL(for: template.id).path))
        XCTAssertEqual(thumbnail.size, CGSize(width: 300, height: 300))
    }

    func testLegacyJSONDrawingLoadsAndIsReplacedOnNextSave() throws {
        let restore = try preserveSavedFiles(of: "free-draw")
        defer { restore() }
        let original = CanvasEngine(template: nil, restore: false)
        box(original)
        original.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: true)
        let legacy = CanvasSnapshot(size: original.size, lines: Data(original.lines),
                                    paint: Data(original.paint), glitter: Data(original.glitterMask))
        try? FileManager.default.removeItem(at: savedFileURL("free-draw", "mandolino"))
        try JSONEncoder().encode(legacy).write(to: savedFileURL("free-draw", "json"))
        let restored = CanvasEngine(template: nil)
        XCTAssertNil(restored.errorMessage)
        XCTAssertEqual(restored.lines, original.lines)
        XCTAssertEqual(restored.paint, original.paint)
        XCTAssertEqual(restored.glitterMask, original.glitterMask)
        restored.fill(at: CGPoint(x: 0.5, y: 0.5), color: blue, glitter: false)
        restored.save()
        XCTAssertFalse(FileManager.default.fileExists(atPath: try savedFileURL("free-draw", "json").path))
        XCTAssertEqual(CanvasEngine(template: nil).paint, restored.paint)
    }

    func testLegacyDrawingsAreConvertedWithThumbnails() throws {
        let restore = try preserveSavedFiles(of: "free-draw")
        defer { restore() }
        let original = CanvasEngine(template: nil, restore: false)
        box(original)
        original.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: true)
        let legacy = CanvasSnapshot(size: original.size, lines: Data(original.lines),
                                    paint: Data(original.paint), glitter: Data(original.glitterMask))
        try? FileManager.default.removeItem(at: savedFileURL("free-draw", "mandolino"))
        try? FileManager.default.removeItem(at: savedFileURL("free-draw", "png"))
        try JSONEncoder().encode(legacy).write(to: savedFileURL("free-draw", "json"))
        CanvasEngine.convertLegacyDrawings()
        XCTAssertFalse(FileManager.default.fileExists(atPath: try savedFileURL("free-draw", "json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: try savedFileURL("free-draw", "png").path))
        let converted = CanvasEngine(template: nil)
        XCTAssertNil(converted.errorMessage)
        XCTAssertEqual(converted.lines, original.lines)
        XCTAssertEqual(converted.paint, original.paint)
        XCTAssertEqual(converted.glitterMask, original.glitterMask)
    }

    func testMirrorRepeatsBrushStrokesAroundTheCenterInOneUndoStep() {
        let engine = CanvasEngine(template: nil, size: 200, restore: false)
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.6, y: 0.2), to: CGPoint(x: 0.6, y: 0.2), tool: .brush, width: 30,
                    color: red, symmetry: 4)
        engine.endStroke()
        // Four turns, each also mirrored: every point (±0.1, ±0.3) and (±0.3, ±0.1) from the center.
        for point in [(0.6, 0.2), (0.4, 0.2), (0.6, 0.8), (0.4, 0.8), (0.8, 0.4), (0.8, 0.6), (0.2, 0.4), (0.2, 0.6)] {
            XCTAssertEqual(pixel(engine, point.0, point.1), [red.red, red.green, red.blue], "\(point)")
        }
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [255, 255, 255])
        XCTAssertEqual(pixel(engine, 0.1, 0.1), [255, 255, 255])
        XCTAssertEqual(engine.undoCount, 1)
        engine.undo()
        XCTAssertTrue(engine.paint.allSatisfy { $0 == 255 })
    }

    func testMirroredShapesAndFillReachEveryMatchingSpace() {
        let engine = CanvasEngine(template: nil, size: 200, restore: false)
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.6, y: 0.15), to: CGPoint(x: 0.7, y: 0.25), tool: .square, width: 6,
                    symmetry: 4)
        engine.endStroke()
        let centers = [(0.65, 0.2), (0.35, 0.2), (0.65, 0.8), (0.35, 0.8),
                       (0.8, 0.35), (0.8, 0.65), (0.2, 0.35), (0.2, 0.65)]
        for center in centers {
            XCTAssertLessThan(engine.lines[Int(center.1 * 200 - 10) * 200 + Int(center.0 * 200)], 200,
                              "A mirrored square should have an outline above \(center)")
        }
        let before = engine.undoCount
        XCTAssertTrue(engine.fill(at: CGPoint(x: 0.65, y: 0.2), color: blue, glitterStyle: .none, symmetry: 4))
        for center in centers {
            XCTAssertEqual(pixel(engine, center.0, center.1), [blue.red, blue.green, blue.blue], "\(center)")
        }
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [255, 255, 255], "The space around the squares stays white")
        XCTAssertEqual(engine.undoCount, before + 1)
        engine.undo()
        XCTAssertEqual(pixel(engine, 0.35, 0.8), [255, 255, 255])
    }

    func testProgressCountsColoredSpacesUntilThePageIsFinished() {
        let engine = CanvasEngine(template: MandalaTemplate.all[0], size: 300, restore: false)
        let map = SpaceMap(lines: engine.lines, size: 300)
        XCTAssertGreaterThanOrEqual(map.sizes.count, 6)
        XCTAssertEqual(map.progress(paint: engine.paint), PageProgress(done: 0, total: map.sizes.count))
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none)
        XCTAssertEqual(map.progress(paint: engine.paint).done, 1)
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: PaintColor.palette[19], glitterStyle: .none)
        XCTAssertEqual(map.progress(paint: engine.paint).done, 0, "White paint, like erasing, is not coloring")
        for space in 0..<map.sizes.count {
            let pixel = try! XCTUnwrap(map.labels.firstIndex(of: Int32(space)))
            engine.fill(at: CGPoint(x: (CGFloat(pixel % 300) + 0.5) / 300, y: (CGFloat(pixel / 300) + 0.5) / 300),
                        color: blue, glitterStyle: .none,
                        options: PaintOptions(effect: .dots, secondColor: PaintColor.palette[19]))
        }
        XCTAssertTrue(map.progress(paint: engine.paint).finished, "Dots on white still count as colored")
    }

    func testRulerStarAndLineStarDrawFillableOutlines() {
        let engine = CanvasEngine(template: nil, size: 300, restore: false)
        // The ruler previews while dragging and keeps only the final straight line.
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.1), to: CGPoint(x: 0.9, y: 0.5), tool: .ruler, width: 6)
        engine.draw(from: CGPoint(x: 0.1, y: 0.1), to: CGPoint(x: 0.9, y: 0.1), tool: .ruler, width: 6)
        engine.endStroke()
        XCTAssertLessThan(engine.lines[30 * 300 + 150], 200, "The straight line runs along y = 0.1")
        XCTAssertEqual(engine.lines[90 * 300 + 150], 255, "The earlier preview leaves no line behind")

        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.2), to: CGPoint(x: 0.45, y: 0.55), tool: .star, width: 6)
        engine.endStroke()
        XCTAssertTrue(engine.fill(at: CGPoint(x: 0.275, y: 0.39), color: red, glitterStyle: .none))
        XCTAssertEqual(pixel(engine, 0.275, 0.39), [red.red, red.green, red.blue])
        XCTAssertEqual(pixel(engine, 0.12, 0.53), [255, 255, 255], "The star is closed")

        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.55, y: 0.45), to: CGPoint(x: 0.95, y: 0.85), tool: .lineStar, width: 6)
        engine.endStroke()
        let map = SpaceMap(lines: engine.lines, size: 300)
        let center = Int(0.66 * 300) * 300 + Int(0.75 * 300)
        let tip = Int(0.52 * 300) * 300 + Int(0.75 * 300)
        XCTAssertGreaterThanOrEqual(map.labels[center], 0, "The middle pentagon is its own space")
        XCTAssertGreaterThanOrEqual(map.labels[tip], 0, "Each tip is its own space")
        XCTAssertNotEqual(map.labels[center], map.labels[tip])
    }

    func testFillsReachTheSoftEdgeOfOutlines() {
        // A circle, because straight lines along the pixel grid have no soft edge pixels.
        let engine = CanvasEngine(template: nil, size: 200, restore: false)
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.2, y: 0.2), to: CGPoint(x: 0.8, y: 0.8), tool: .circle, width: 12)
        engine.endStroke()
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none)
        let soft = (0..<engine.lines.count).filter { engine.lines[$0] < 200 && engine.lines[$0] > 40 }
        XCTAssertFalse(soft.isEmpty)
        // Soft pixels on the inner side of the ring (radius 60 px at this size, line 2.4 px wide).
        let insideEdge = soft.filter { index in
            hypot(CGFloat(index % 200) + 0.5 - 100, CGFloat(index / 200) + 0.5 - 100) < 60
        }
        XCTAssertFalse(insideEdge.isEmpty)
        for index in insideEdge {
            XCTAssertEqual(Array(engine.paint[index * 4..<index * 4 + 3]), [red.red, red.green, red.blue],
                           "No white ring between the color and the line")
        }
        XCTAssertEqual(pixel(engine, 0.1, 0.1), [255, 255, 255], "The color does not cross the line")
    }

    func testClearedOrDeletedOwnDrawingsAreRemoved() throws {
        let id = CanvasEngine.newOwnDrawingID()
        defer { try? FileManager.default.removeItem(at: savedFileURL(id, "mandolino")) }
        let engine = CanvasEngine(template: nil, documentID: id, restore: false)
        box(engine)
        engine.save()
        XCTAssertTrue(CanvasEngine.ownDrawingIDs().contains(id))
        engine.reset()
        engine.save()
        XCTAssertFalse(CanvasEngine.ownDrawingIDs().contains(id), "A cleared own drawing is removed, not kept blank")
        engine.undo()
        engine.save()
        XCTAssertTrue(CanvasEngine.ownDrawingIDs().contains(id), "Undo brings it back while still on the page")
        engine.delete()
        XCTAssertFalse(CanvasEngine.ownDrawingIDs().contains(id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: try CanvasEngine.thumbnailURL(for: id).path))
        box(engine)
        engine.save()
        XCTAssertFalse(CanvasEngine.ownDrawingIDs().contains(id), "Leaving after deleting doesn't save it again")
    }

    func testCatalogHasLargeDistinctCollectionsAndEnclosedColorableRegions() {
        XCTAssertGreaterThanOrEqual(MandalaTemplate.all.count, 96)
        XCTAssertEqual(Set(MandalaTemplate.all.map(\.id)).count, MandalaTemplate.all.count)
        for level in Difficulty.allCases where level != .art {
            XCTAssertGreaterThanOrEqual(MandalaTemplate.all.filter { $0.difficulty == level }.count, 24)
        }
        XCTAssertEqual(MandalaTemplate.all.filter { $0.difficulty == .art }.count, 12, "Six mandalas and six animals")
        var outlines = Set<Data>()
        for template in MandalaTemplate.all {
            let detailed = template.difficulty == .expert || template.difficulty == .art
            let engine = CanvasEngine(template: template, size: detailed ? 600 : 300, restore: false)
            let regions = enclosedRegions(engine)
            let minimum: Int
            switch template.difficulty {
            case .easy: minimum = 6
            case .medium, .hard: minimum = 15
            case .expert: minimum = 150
            case .art: minimum = 40
            }
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

    func testWeightedMixturesUseEveryIngredientAndRespectAmounts() {
        let white = PaintColor.palette[19]
        let black = PaintColor.palette[20]
        let mixed = PaintColor.mix([(red, 2), (white, 3), (black, 5)])
        XCTAssertEqual(mixed.red, UInt8((Double(red.red) * 0.2 + 255 * 0.3 + Double(black.red) * 0.5).rounded()))
        XCTAssertEqual(mixed.green, UInt8((Double(red.green) * 0.2 + 255 * 0.3 + Double(black.green) * 0.5).rounded()))
        XCTAssertEqual(mixed.blue, UInt8((Double(red.blue) * 0.2 + 255 * 0.3 + Double(black.blue) * 0.5).rounded()))
        let reordered = PaintColor.mix([(black, 50), (red, 20), (white, 30)])
        XCTAssertEqual([mixed.red, mixed.green, mixed.blue],
                       [reordered.red, reordered.green, reordered.blue])
        let mostlyRed = PaintColor.mix([(red, 99), (blue, 1)])
        let mostlyBlue = PaintColor.mix([(red, 1), (blue, 99)])
        XCTAssertGreaterThan(mostlyRed.red, mostlyBlue.red)
        XCTAssertGreaterThan(mostlyBlue.blue, mostlyRed.blue)
        let single = PaintColor.mix([(red, 42)])
        XCTAssertEqual([single.red, single.green, single.blue], [red.red, red.green, red.blue])
        let same = PaintColor.mix([(blue, 10), (blue, 90)])
        XCTAssertEqual([same.red, same.green, same.blue], [blue.red, blue.green, blue.blue])
    }

    func testCrystalFinishesAreDistinctRecolorableAndUndoable() {
        let engine = CanvasEngine(template: nil, size: 150, restore: false)
        box(engine)
        let lines = engine.lines
        var textures = Set<Data>()
        for style in GlitterStyle.allCases where style != .none {
            engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: style)
            XCTAssertTrue(textures.insert(Data(engine.paint)).inserted)
            XCTAssertEqual(engine.glitterMask[75 * 150 + 75], style.rawValue)
            XCTAssertFalse(engine.sparklePoints.isEmpty)
            XCTAssertEqual(pixel(engine, 0.1, 0.1), [255, 255, 255])
            let textured = engine.paint
            engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: blue, glitterStyle: .none)
            XCTAssertEqual(pixel(engine, 0.5, 0.5), [blue.red, blue.green, blue.blue])
            XCTAssertTrue(engine.glitterMask.allSatisfy { $0 == 0 })
            engine.undo()
            XCTAssertEqual(engine.paint, textured)
            XCTAssertEqual(engine.glitterMask[75 * 150 + 75], style.rawValue)
        }
        XCTAssertEqual(engine.lines, lines)
    }

    func testColoredFreestyleOnMandalaPreservesOutlinesAndHistory() {
        let engine = CanvasEngine(template: MandalaTemplate.all[0], size: 200, restore: false)
        let lines = engine.lines
        let blank = engine.paint
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.15), to: CGPoint(x: 0.4, y: 0.15),
                    tool: .brush, width: 36, color: blue, glitterStyle: .diamond)
        engine.endStroke()
        XCTAssertEqual(engine.lines, lines)
        XCTAssertEqual(engine.glitterMask[30 * 200 + 50], GlitterStyle.diamond.rawValue)
        XCTAssertEqual(pixel(engine, 0.8, 0.85), [255, 255, 255])
        let painted = engine.paint
        XCTAssertNotEqual(painted, blank)
        XCTAssertEqual(engine.undoCount, 1)
        engine.undo()
        XCTAssertEqual(engine.paint, blank)
        XCTAssertTrue(engine.glitterMask.allSatisfy { $0 == 0 })
        engine.redo()
        XCTAssertEqual(engine.paint, painted)
        engine.reset()
        XCTAssertEqual(engine.lines, lines)
        engine.undo()
        XCTAssertEqual(engine.paint, painted)
    }

    func testSavedFreestyleAndActualPreviewRefresh() throws {
        try verifySavedPreview(template: nil)
        try verifySavedPreview(template: MandalaTemplate.all[0])
    }

    private func verifySavedPreview(template: MandalaTemplate?) throws {
        let restore = try preserveSavedFiles(of: template?.id ?? "free-draw")
        defer { restore() }
        let engine = CanvasEngine(template: template, restore: false)
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: blue, glitterStyle: .none,
                    options: PaintOptions(effect: .gradient, secondColor: red, direction: .vertical))
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.25), to: CGPoint(x: 0.4, y: 0.25),
                    tool: .brush, width: 36, color: red, glitterStyle: .amethyst,
                    options: PaintOptions(effect: .stripes, secondColor: blue))
        engine.endStroke()
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.2, y: 0.25), to: CGPoint(x: 0.3, y: 0.25),
                    tool: .eraser, width: 18)
        engine.endStroke()
        engine.save()
        let restored = CanvasEngine(template: template)
        XCTAssertNil(restored.errorMessage)
        XCTAssertEqual(restored.paint, engine.paint)
        XCTAssertEqual(restored.glitterMask, engine.glitterMask)
        let first = try CanvasEngine.preview(template: template)
        XCTAssertEqual(first.size.width, 300)
        XCTAssertEqual(try renderedBytes(first), try renderedBytes(resized(engine.image)))
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.1, y: 0.75), to: CGPoint(x: 0.9, y: 0.75),
                    tool: .brush, width: 36, color: blue)
        engine.endStroke()
        engine.save()
        let second = try CanvasEngine.preview(template: template)
        XCTAssertNotEqual(try renderedBytes(first), try renderedBytes(second))
        XCTAssertEqual(try renderedBytes(second), try renderedBytes(resized(engine.image)))
    }

    private func savedFileURL(_ id: String, _ pathExtension: String) throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                appropriateFor: nil, create: true)
            .appendingPathComponent("Drawings", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(id).appendingPathExtension(pathExtension)
    }

    /// Snapshots a page's saved files; the returned closure puts them back exactly as they were.
    private func preserveSavedFiles(of id: String) throws -> () -> Void {
        let urls = try ["mandolino", "json", "png"].map { try savedFileURL(id, $0) }
        let previous = urls.map { try? Data(contentsOf: $0) }
        return {
            for (url, data) in zip(urls, previous) {
                if let data { try? data.write(to: url, options: .atomic) }
                else { try? FileManager.default.removeItem(at: url) }
            }
        }
    }

    private func pencil(_ engine: CanvasEngine, _ points: [CGPoint]) {
        engine.beginStroke()
        for pair in zip(points, points.dropFirst()) {
            engine.draw(from: pair.0, to: pair.1, tool: .pencil, width: 6)
        }
        engine.endStroke()
    }

    private func arc(from start: CGFloat, to end: CGFloat, radius: CGFloat = 0.3) -> [CGPoint] {
        (0...80).map { i in
            let angle = start + (end - start) * CGFloat(i) / 80
            return CGPoint(x: 0.5 + cos(angle) * radius, y: 0.5 + sin(angle) * radius)
        }
    }

    func testPencilLoopWithASmallGapIsClosedSoTheFillStaysInside() {
        let engine = CanvasEngine(template: nil, size: 300, restore: false)
        // About 3 % of the page is left open between the end and the start.
        pencil(engine, arc(from: 0.1, to: 2 * .pi))
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: false)
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [red.red, red.green, red.blue])
        XCTAssertEqual(pixel(engine, 0.05, 0.05), [255, 255, 255], "The fill must not leak out of the gap")
        engine.undo()
        engine.undo()
        XCTAssertFalse(engine.lines.contains { $0 < 200 }, "One Undo removes the line together with its join")
    }

    func testPencilLineStoppingShortOfAnotherLineIsJoinedToIt() {
        let engine = CanvasEngine(template: nil, size: 300, restore: false)
        box(engine)
        pencil(engine, [CGPoint(x: 0.2, y: 0.5), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.785, y: 0.5)])
        engine.fill(at: CGPoint(x: 0.5, y: 0.3), color: red, glitter: false)
        XCTAssertEqual(pixel(engine, 0.5, 0.3), [red.red, red.green, red.blue])
        XCTAssertEqual(pixel(engine, 0.5, 0.7), [255, 255, 255], "The line now splits the box in two")
    }

    func testMirroredHalfShapeStoppingShortOfTheMirrorIsJoinedToItsCopy() {
        let engine = CanvasEngine(template: nil, size: 300, restore: false)
        // Half a petal right of the middle line; the mirror draws the other half. Both ends stop
        // a little short of the middle, so the halves don't meet.
        let half = (0...40).map { i -> CGPoint in
            let a = CGFloat(i) / 40 * .pi
            return CGPoint(x: 0.51 + sin(a) * 0.1, y: 0.3 - CGFloat(i) / 40 * 0.2)
        }
        engine.beginStroke()
        for pair in zip(half, half.dropFirst()) {
            engine.draw(from: pair.0, to: pair.1, tool: .pencil, width: 6, symmetry: 6)
        }
        engine.endStroke()
        engine.fill(at: CGPoint(x: 0.55, y: 0.2), color: red, glitterStyle: .none, symmetry: 6)
        XCTAssertEqual(pixel(engine, 0.55, 0.2), [red.red, red.green, red.blue])
        XCTAssertEqual(pixel(engine, 0.03, 0.03), [255, 255, 255], "The fill must stay inside the petals")
    }

    private func brushRing(_ engine: CanvasEngine, color: PaintColor) {
        engine.beginStroke()
        let ring = arc(from: 0, to: 2 * .pi + 0.2, radius: 0.25)
        for pair in zip(ring, ring.dropFirst()) {
            engine.draw(from: pair.0, to: pair.1, tool: .brush, width: 18, color: color)
        }
        engine.endStroke()
    }

    func testFillStaysInsideAShapeDrawnWithTheBrush() throws {
        let engine = CanvasEngine(template: nil, size: 300, restore: false)
        brushRing(engine, color: blue)
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none)
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [red.red, red.green, red.blue])
        XCTAssertEqual(pixel(engine, 0.05, 0.05), [255, 255, 255], "The fill must stay inside the brush ring")
        XCTAssertEqual(pixel(engine, 0.75, 0.5), [blue.red, blue.green, blue.blue], "The ring keeps its color")
        // Tapping the ring itself recolors just the ring.
        let green = PaintColor.palette[6]
        engine.fill(at: CGPoint(x: 0.75, y: 0.5), color: green, glitterStyle: .none)
        XCTAssertEqual(pixel(engine, 0.75, 0.5), [green.red, green.green, green.blue])
        XCTAssertEqual(pixel(engine, 0.5, 0.5), [red.red, red.green, red.blue])
        // The wall comes back with Undo and survives saving.
        engine.undo()
        engine.undo()
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none)
        XCTAssertEqual(pixel(engine, 0.05, 0.05), [255, 255, 255])
    }

    func testErasedOrWhiteBrushStrokesAreNoWall() {
        let engine = CanvasEngine(template: nil, size: 300, restore: false)
        brushRing(engine, color: PaintColor.palette[19])
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none)
        XCTAssertEqual(pixel(engine, 0.05, 0.05), [red.red, red.green, red.blue], "Invisible white strokes don't block")
        let other = CanvasEngine(template: nil, size: 300, restore: false)
        brushRing(other, color: blue)
        other.beginStroke()
        other.draw(from: CGPoint(x: 0.6, y: 0.5), to: CGPoint(x: 0.9, y: 0.5), tool: .eraser, width: 36)
        other.endStroke()
        other.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitterStyle: .none)
        XCTAssertEqual(pixel(other, 0.05, 0.05), [red.red, red.green, red.blue], "Rubbed out strokes don't block")
    }

    func testCancelledStrokeIsTakenBackWithoutAnUndoStep() {
        let engine = CanvasEngine(template: nil, size: 300, restore: false)
        engine.beginStroke()
        engine.draw(from: CGPoint(x: 0.2, y: 0.5), to: CGPoint(x: 0.6, y: 0.5), tool: .pencil, width: 6)
        engine.draw(from: CGPoint(x: 0.2, y: 0.7), to: CGPoint(x: 0.6, y: 0.7), tool: .brush, width: 18, color: red)
        engine.cancelStroke()
        XCTAssertFalse(engine.lines.contains { $0 < 200 })
        XCTAssertEqual(pixel(engine, 0.4, 0.7), [255, 255, 255])
        XCTAssertEqual(engine.undoCount, 0)
    }

    func testCanvasPassesTouchesOnWithoutDelay() {
        XCTAssertFalse(ZoomCanvas().delaysContentTouches, "Lines must start where the finger lands")
    }

    func testOpenPencilShapesStayOpen() {
        let engine = CanvasEngine(template: nil, size: 300, restore: false)
        // A letter C: its opening is wide compared with the line, so it is not closed.
        pencil(engine, arc(from: 0.8, to: 2 * .pi - 0.8))
        pencil(engine, [CGPoint(x: 0.1, y: 0.9), CGPoint(x: 0.3, y: 0.9)])
        engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: red, glitter: false)
        XCTAssertEqual(pixel(engine, 0.05, 0.05), [red.red, red.green, red.blue])
        XCTAssertGreaterThan(engine.lines[Int(0.9 * 300) * 300 + Int(0.35 * 300)], 240,
                             "A short line far from others gets nothing added")
    }

    func testShinyGoldAndSilverPaintWithAMetalSheen() {
        let gold = PaintColor.palette[40], silver = PaintColor.palette[41]
        XCTAssertTrue(gold.isMetallic && silver.isMetallic)
        XCTAssertFalse(PaintColor.palette[25].isMetallic, "The flat Gold stays a plain color")
        for metal in [gold, silver] {
            let engine = CanvasEngine(template: nil, size: 300, restore: false)
            box(engine)
            engine.fill(at: CGPoint(x: 0.5, y: 0.5), color: metal, glitterStyle: .none)
            var brightness: [Int] = []
            for y in stride(from: 0.25, to: 0.75, by: 0.02) {
                for x in stride(from: 0.25, to: 0.75, by: 0.02) {
                    let p = pixel(engine, x, y)
                    XCTAssertNotEqual(p, [255, 255, 255], "Metal paint always counts as colored")
                    brightness.append(Int(p[0]) + Int(p[1]) + Int(p[2]))
                }
            }
            XCTAssertGreaterThan(brightness.max()! - brightness.min()!, 200, "\(metal.name) shows shadow and shine")
        }
    }

    func testFinishedPageGetsItsStarEvenWhenLeftRightAway() throws {
        let template = try XCTUnwrap(MandalaTemplate.all.first { $0.id == "flower" })
        UserDefaults.standard.removeObject(forKey: CanvasEngine.finishedPagesKey)
        var engine: CanvasEngine? = CanvasEngine(template: template, restore: false)
        let map = SpaceMap(lines: engine!.lines, size: engine!.size)
        for space in 0..<map.sizes.count {
            let pixel = try XCTUnwrap(map.labels.firstIndex(of: Int32(space)))
            engine!.fill(at: CGPoint(x: (CGFloat(pixel % engine!.size) + 0.5) / CGFloat(engine!.size),
                                     y: (CGFloat(pixel / engine!.size) + 0.5) / CGFloat(engine!.size)),
                         color: blue, glitterStyle: .none)
        }
        engine = nil
        let starred = NSPredicate { _, _ in
            (UserDefaults.standard.string(forKey: CanvasEngine.finishedPagesKey) ?? "").split(separator: ",").contains("flower")
        }
        wait(for: [expectation(for: starred, evaluatedWith: nil)], timeout: 10)
        UserDefaults.standard.removeObject(forKey: CanvasEngine.finishedPagesKey)
    }

    func testPagesFinishedBeforeStarsExistedAreStarredOnce() throws {
        let template = try XCTUnwrap(MandalaTemplate.all.first { $0.id == "flower-2" })
        let engine = CanvasEngine(template: template, restore: false)
        let map = SpaceMap(lines: engine.lines, size: engine.size)
        for space in 0..<map.sizes.count {
            let pixel = try XCTUnwrap(map.labels.firstIndex(of: Int32(space)))
            engine.fill(at: CGPoint(x: (CGFloat(pixel % engine.size) + 0.5) / CGFloat(engine.size),
                                    y: (CGFloat(pixel / engine.size) + 0.5) / CGFloat(engine.size)),
                        color: blue, glitterStyle: .none)
        }
        engine.save()
        // Like a page colored with an older version: saved, but never counted.
        let flushed = expectation(description: "progress counted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { DispatchQueue.main.async { flushed.fulfill() } }
        wait(for: [flushed], timeout: 5)
        UserDefaults.standard.removeObject(forKey: CanvasEngine.finishedPagesKey)
        UserDefaults.standard.removeObject(forKey: "finishedPagesChecked")
        CanvasEngine.starFinishedPages()
        let starred = NSPredicate { _, _ in
            (UserDefaults.standard.string(forKey: CanvasEngine.finishedPagesKey) ?? "").split(separator: ",").contains("flower-2")
        }
        wait(for: [expectation(for: starred, evaluatedWith: nil)], timeout: 10)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "finishedPagesChecked"))
        engine.delete()
        UserDefaults.standard.removeObject(forKey: CanvasEngine.finishedPagesKey)
    }

    private func resized(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: 300, height: 300))
        }
    }

    private func renderedBytes(_ image: UIImage) throws -> Data {
        let cgImage = try XCTUnwrap(image.cgImage)
        return try XCTUnwrap(cgImage.dataProvider?.data) as Data
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
