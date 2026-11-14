import XCTest

final class MandolinoUITests: XCTestCase {
    func testMandalasAllLevelsColorSparkleUndoAndShare() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        app.launch()
        XCTAssertTrue(app.buttons["template-flower"].waitForExistence(timeout: 20))
        screenshot("Gallery")
        app.segmentedControls["difficulty"].buttons["Medium"].tap()
        XCTAssertTrue(app.buttons["template-owl"].waitForExistence(timeout: 5))
        app.segmentedControls["difficulty"].buttons["Hard"].tap()
        XCTAssertTrue(app.buttons["template-lion"].waitForExistence(timeout: 5))
        app.segmentedControls["difficulty"].buttons["Expert"].tap()
        XCTAssertTrue(app.buttons["template-kaleidoscope"].waitForExistence(timeout: 5))
        screenshot("Expert collection")
        app.segmentedControls["difficulty"].buttons["Easy"].tap()
        app.buttons["template-flower"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["drawing-canvas"].waitForExistence(timeout: 10))
        reveal(app.buttons["color-10"], in: app)
        app.buttons["color-10"].tap()
        reveal(app.buttons["glitter-1"], in: app)
        app.buttons["glitter-1"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Sparkle coloring")
        app.buttons["undo"].tap()
        XCTAssertTrue(app.buttons["redo"].isEnabled)
        app.buttons["redo"].tap()
        app.buttons["share"].tap()
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 10)
                      || app.otherElements["ActivityListView"].exists
                      || app.navigationBars.count > 0)
        screenshot("Share drawing")
    }

    func testFreeDrawingShapesFillAndPersistence() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        app.launch()
        app.buttons["free-draw"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        app.buttons["clear"].tap()
        app.buttons["Clear this drawing"].tap()
        app.buttons["tool-square"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.25))
            .press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.75)))
        reveal(app.buttons["color-6"], in: app)
        app.buttons["color-6"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Free draw filled shape")
        app.buttons["pages"].tap()
        XCTAssertTrue(app.buttons["free-draw"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.buttons["free-draw"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["drawing-canvas"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts["Drawing needs attention"].exists)
        reveal(app.buttons["glitter-1"], in: app)
        XCTAssertTrue(app.buttons["glitter-1"].isHittable)
        reveal(app.buttons["color-19"], in: app)
        reveal(app.buttons["color-19"], in: app)
        XCTAssertTrue(app.buttons["color-19"].isHittable)
        reveal(app.buttons["color-3"], in: app)
        reveal(app.buttons["color-1"], in: app)
        app.buttons["color-1"].tap()
        app.descendants(matching: .any)["drawing-canvas"]
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Restored free drawing")
    }

    func testLandscapeAnimalColoringAndRotation() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        XCTAssertTrue(app.buttons["template-flower"].waitForExistence(timeout: 10))
        app.segmentedControls["difficulty"].buttons["Hard"].tap()
        app.buttons["template-lion"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["color-19"].isHittable)
        app.buttons["color-3"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.47)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Landscape lion")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["color-19"].waitForExistence(timeout: 5))
        reveal(app.buttons["glitter-1"], in: app)
        XCTAssertTrue(app.buttons["glitter-1"].isHittable)
        screenshot("Portrait lion")
    }

    func testExpertPageSupportsZoomAndFill() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        app.launch()
        app.segmentedControls["difficulty"].buttons["Expert"].tap()
        app.buttons["template-kaleidoscope"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        canvas.pinch(withScale: 2, velocity: 1)
        let magnified = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (Double(canvas.value as? String ?? "") ?? 0) > 150
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [magnified], timeout: 5), .completed,
                       "Pinching must actually magnify the paper")
        reveal(app.buttons["color-13"], in: app)
        app.buttons["color-13"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Expert zoomed coloring")
    }

    func testGermanDefaultLanguageSwitchMixingAndEraser() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestGerman"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Wähle ein Ausmalbild"].waitForExistence(timeout: 10))
        app.buttons["template-flower"].tap()
        XCTAssertTrue(app.staticTexts["Farbkasten"].waitForExistence(timeout: 10))
        reveal(app.buttons["mix-colors"], in: app)
        app.buttons["mix-colors"].tap()
        XCTAssertTrue(app.staticTexts["Farben mischen"].waitForExistence(timeout: 5))
        app.buttons["mix-color-10"].tap()
        app.buttons["mix-color-4"].tap()
        XCTAssertTrue(app.buttons["use-mixed-color"].isHittable)
        screenshot("German color mixer")
        app.buttons["use-mixed-color"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        reveal(app.buttons["glitter-1"], in: app)
        app.buttons["glitter-1"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let firstFrame = canvas.screenshot().pngRepresentation
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertNotEqual(firstFrame, canvas.screenshot().pngRepresentation,
                          "Glitter must visibly twinkle, not just be a static pattern")
        screenshot("German glitter paint")
        reveal(app.buttons["eraser"], in: app)
        app.buttons["eraser"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        app.buttons["undo"].tap()
        app.buttons["editor-language"].tap()
        XCTAssertTrue(app.staticTexts["Color box"].waitForExistence(timeout: 5))
        app.buttons["pages"].tap()
        XCTAssertTrue(app.staticTexts["Pick a coloring page"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["Pick a coloring page"].waitForExistence(timeout: 10))
        app.segmentedControls["language-switcher"].buttons["Deutsch"].tap()
        XCTAssertTrue(app.staticTexts["Wähle ein Ausmalbild"].waitForExistence(timeout: 5))
        screenshot("German gallery")
    }

    func testFreestylePreviewCrystalPreferencesAndWeightedMixer() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        XCTAssertTrue(app.buttons["template-flower"].waitForExistence(timeout: 20))
        let preview = app.descendants(matching: .any)["preview-flower"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        let before = preview.screenshot().pngRepresentation
        app.buttons["template-flower"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        app.buttons["clear"].tap()
        app.buttons["Clear this drawing"].tap()
        reveal(app.buttons["color-10"], in: app)
        app.buttons["color-10"].tap()
        reveal(app.buttons["glitter-2"], in: app)
        app.buttons["glitter-2"].tap()
        reveal(app.buttons["tool-brush"], in: app)
        app.buttons["tool-brush"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.15))
            .press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.15)))
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        reveal(app.buttons["color-39"], in: app)
        app.buttons["color-39"].tap()
        reveal(app.buttons["color-10"], in: app)
        app.buttons["color-10"].tap()
        reveal(app.buttons["glitter-2"], in: app)
        XCTAssertTrue(app.buttons["glitter-2"].isSelected)
        reveal(app.buttons["mix-colors"], in: app)
        app.buttons["mix-colors"].tap()
        XCTAssertTrue(app.buttons["mix-add-color"].waitForExistence(timeout: 5))
        app.buttons["mix-add-color"].tap()
        XCTAssertTrue(app.sliders["mix-amount-2"].waitForExistence(timeout: 5))
        app.sliders["mix-amount-0"].adjust(toNormalizedSliderPosition: 0.9)
        app.sliders["mix-amount-1"].adjust(toNormalizedSliderPosition: 0.2)
        app.sliders["mix-amount-2"].adjust(toNormalizedSliderPosition: 0.4)
        screenshot("Weighted three-color mixture")
        app.buttons["use-mixed-color"].tap()
        reveal(app.buttons["tool-brush"], in: app)
        XCTAssertTrue(app.buttons["tool-brush"].isSelected)
        app.buttons["pages"].tap()
        XCTAssertTrue(app.buttons["template-flower"].waitForExistence(timeout: 10))
        let refreshed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            preview.exists && preview.screenshot().pngRepresentation != before
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [refreshed], timeout: 10), .completed)
        screenshot("Actual saved artwork preview")
        app.buttons["template-flower"].tap()
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        reveal(app.buttons["color-10"], in: app)
        app.buttons["color-10"].tap()
        reveal(app.buttons["glitter-2"], in: app)
        XCTAssertTrue(app.buttons["glitter-2"].isSelected)
    }

    func testQuickFinishesPatternsGradientEndpointsAndStrokeEraser() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        app.launch()
        app.buttons["template-flower"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        reveal(app.buttons["glitter-2"], in: app)
        app.buttons["glitter-2"].tap()
        XCTAssertTrue(app.buttons["glitter-2"].isSelected)
        app.buttons["glitter-4"].tap()
        XCTAssertTrue(app.buttons["glitter-4"].isSelected)
        app.buttons["glitter-0"].tap()
        XCTAssertTrue(app.buttons["glitter-0"].isSelected)
        reveal(app.buttons["effect-gradient"], in: app)
        app.buttons["effect-gradient"].tap()
        reveal(app.buttons["gradient-from"], in: app)
        app.buttons["gradient-from"].tap()
        app.buttons["endpoint-color-1"].tap()
        app.buttons["gradient-to"].tap()
        app.buttons["endpoint-color-10"].tap()
        XCTAssertEqual(app.buttons["gradient-from"].label, "From: Red")
        XCTAssertEqual(app.buttons["gradient-to"].label, "To: Ocean")
        reveal(app.segmentedControls["gradient-direction"], in: app)
        app.segmentedControls["gradient-direction"].buttons["Vertical"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Configurable gradient")
        reveal(app.buttons["effect-chevron"], in: app)
        app.buttons["effect-chevron"].tap()
        reveal(app.buttons["tool-brush"], in: app)
        app.buttons["tool-brush"].tap()
        let a = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.15))
        let b = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.15))
        a.press(forDuration: 0.1, thenDragTo: b)
        screenshot("Two-color patterned brush")
        reveal(app.buttons["eraser"], in: app)
        app.buttons["eraser"].tap()
        a.press(forDuration: 0.1, thenDragTo: b)
        app.buttons["undo"].tap()
        XCTAssertTrue(app.buttons["redo"].isEnabled)
        app.buttons["redo"].tap()
        screenshot("Erased freestyle stroke")
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        guard !element.isHittable else { return }
        if element.identifier.hasPrefix("color-") {
            let palette = app.scrollViews["color-palette"]
            reveal(palette, in: app)
            for _ in 0..<8 {
                palette.swipeRight()
                if element.isHittable { return }
            }
            for _ in 0..<12 {
                palette.swipeLeft()
                if element.isHittable { return }
            }
            return
        }
        let controls = app.scrollViews["painting-controls"]
        for _ in 0..<4 {
            controls.swipeDown()
            if element.isHittable { return }
        }
        for _ in 0..<8 {
            controls.swipeUp()
            if element.isHittable { return }
        }
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
