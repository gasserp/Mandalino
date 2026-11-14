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
