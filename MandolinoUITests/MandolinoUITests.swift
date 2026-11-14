import XCTest

final class MandolinoUITests: XCTestCase {
    func testMandalasAllLevelsColorSparkleUndoAndShare() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        app.launch()
        XCTAssertTrue(app.buttons["template-flower"].waitForExistence(timeout: 20))
        screenshot("Gallery")
        app.buttons["difficulty-medium"].tap()
        XCTAssertTrue(app.buttons["template-owl"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["template-owl-5"].exists, "Each design shows all its versions together")
        app.buttons["difficulty-hard"].tap()
        XCTAssertTrue(app.buttons["template-lion"].waitForExistence(timeout: 5))
        app.buttons["difficulty-expert"].tap()
        XCTAssertTrue(app.buttons["template-kaleidoscope"].waitForExistence(timeout: 5))
        screenshot("Expert collection")
        app.buttons["difficulty-easy"].tap()
        app.buttons["template-flower"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["drawing-canvas"].waitForExistence(timeout: 10))
        pickColor(10, in: app)
        show("glitter-1", in: app).tap()
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
        let ownDrawings = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'own-'"))
        XCTAssertTrue(app.buttons["new-drawing"].waitForExistence(timeout: 10))
        let before = ownDrawings.count
        app.buttons["new-drawing"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["undo"].isEnabled, "A new drawing starts empty")
        app.buttons["tool-lines"].tap()
        app.buttons["tool-square"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.25))
            .press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.75)))
        pickColor(6, in: app)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Free draw filled shape")
        app.buttons["pages"].tap()
        XCTAssertTrue(app.buttons["new-drawing"].waitForExistence(timeout: 5))
        XCTAssertEqual(ownDrawings.count, before + 1, "The new drawing is kept next to the earlier ones")
        app.buttons["new-drawing"].tap()
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        app.buttons["pages"].tap()
        XCTAssertTrue(app.buttons["new-drawing"].waitForExistence(timeout: 5))
        XCTAssertEqual(ownDrawings.count, before + 1, "An empty new drawing is not kept")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["new-drawing"].waitForExistence(timeout: 10))
        ownDrawings.firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["drawing-canvas"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts["Drawing needs attention"].exists)
        XCTAssertTrue(show("glitter-1", in: app).isHittable)
        XCTAssertTrue(show("color-19", in: app).isHittable)
        pickColor(1, in: app)
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
        app.buttons["difficulty-hard"].tap()
        app.buttons["template-lion"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["color-19"].isHittable)
        pickColor(3, in: app)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.47)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Landscape lion")
        XCTAssertTrue(show("glitter-1", in: app).isHittable)
        screenshot("Landscape magic drawer")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(show("color-19", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(show("glitter-1", in: app).isHittable)
        screenshot("Portrait lion")
    }

    func testExpertPageSupportsZoomAndFill() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        app.launch()
        app.buttons["difficulty-expert"].tap()
        app.buttons["template-kaleidoscope"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        canvas.pinch(withScale: 2, velocity: 1)
        let magnified = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (Double(canvas.value as? String ?? "") ?? 0) > 150
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [magnified], timeout: 5), .completed,
                       "Pinching must actually magnify the paper")
        pickColor(13, in: app)
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
        XCTAssertTrue(app.buttons["Füllen"].waitForExistence(timeout: 10))
        show("mix-colors", in: app).tap()
        XCTAssertTrue(app.staticTexts["Farben mischen"].waitForExistence(timeout: 5))
        app.buttons["mix-color-10"].tap()
        app.buttons["mix-color-4"].tap()
        XCTAssertTrue(app.buttons["use-mixed-color"].isHittable)
        screenshot("German color mixer")
        app.buttons["use-mixed-color"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["my-color-0"].exists, "A mix she used stays in My colors")
        show("glitter-1", in: app).tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let firstFrame = canvas.screenshot().pngRepresentation
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertNotEqual(firstFrame, canvas.screenshot().pngRepresentation,
                          "Glitter must visibly twinkle, not just be a static pattern")
        screenshot("German glitter paint")
        app.buttons["eraser"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        app.buttons["undo"].tap()
        app.buttons["more"].tap()
        app.buttons["editor-language"].tap()
        XCTAssertTrue(app.buttons["Fill"].waitForExistence(timeout: 5))
        app.buttons["pages"].tap()
        XCTAssertTrue(app.staticTexts["Pick a coloring page"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["Pick a coloring page"].waitForExistence(timeout: 10))
        app.buttons["gallery-settings"].tap()
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
        // The gallery card is the preview itself.
        let preview = app.buttons["template-flower"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        let before = preview.screenshot().pngRepresentation
        app.buttons["template-flower"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        app.buttons["more"].tap()
        app.buttons["clear"].tap()
        app.buttons["Clear this drawing"].tap()
        pickColor(10, in: app)
        show("glitter-2", in: app).tap()
        app.buttons["tool-brush"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.15))
            .press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.15)))
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        pickColor(39, in: app)
        pickColor(10, in: app)
        XCTAssertTrue(show("glitter-2", in: app).isSelected, "Glitter stays as set when the color changes")
        show("mix-colors", in: app).tap()
        XCTAssertTrue(app.buttons["mix-color-1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["use-mixed-color"].isEnabled, "An empty bowl has no color to use")
        for id in [1, 1, 1, 4, 10, 10] { app.buttons["mix-color-\(id)"].tap() }
        XCTAssertTrue(app.buttons["mix-more-2"].exists, "Three colors are in the bowl")
        app.buttons["mix-less-1"].tap()
        XCTAssertFalse(app.buttons["mix-more-2"].exists, "Taking out the only yellow drop removes yellow")
        screenshot("Weighted drop mixture")
        app.buttons["use-mixed-color"].tap()
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
        pickColor(10, in: app)
        XCTAssertTrue(show("glitter-2", in: app).isSelected, "The glitter choice is kept across pages")
    }

    func testQuickFinishesPatternsGradientEndpointsAndStrokeEraser() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestEnglish"]
        app.launch()
        app.buttons["template-flower"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        show("glitter-2", in: app).tap()
        XCTAssertTrue(app.buttons["glitter-2"].isSelected)
        app.buttons["glitter-4"].tap()
        XCTAssertTrue(app.buttons["glitter-4"].isSelected)
        app.buttons["glitter-0"].tap()
        XCTAssertTrue(app.buttons["glitter-0"].isSelected)
        app.buttons["effect-gradient"].tap()
        app.buttons["gradient-from"].tap()
        app.buttons["endpoint-color-1"].tap()
        app.buttons["gradient-to"].tap()
        app.buttons["endpoint-color-10"].tap()
        XCTAssertEqual(app.buttons["gradient-from"].label, "From: Red")
        XCTAssertEqual(app.buttons["gradient-to"].label, "To: Ocean")
        app.buttons["direction-vertical"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["undo"].isEnabled)
        screenshot("Configurable gradient")
        app.buttons["effect-chevron"].tap()
        app.buttons["tool-brush"].tap()
        let a = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.15))
        let b = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.15))
        a.press(forDuration: 0.1, thenDragTo: b)
        screenshot("Two-color patterned brush")
        app.buttons["eraser"].tap()
        a.press(forDuration: 0.1, thenDragTo: b)
        app.buttons["undo"].tap()
        XCTAssertTrue(app.buttons["redo"].isEnabled)
        app.buttons["redo"].tap()
        screenshot("Erased freestyle stroke")
        pickColor(10, in: app)
        XCTAssertTrue(show("effect-solid", in: app).isSelected,
                      "Picking a color after a pattern paints plain color again")
    }

    /// Returns the tray button with this identifier, first switching the drawer (colors or magic) that holds it.
    private func show(_ id: String, in app: XCUIApplication) -> XCUIElement {
        let element = app.buttons[id]
        if element.exists { return element }
        let magic = ["glitter-", "effect-", "gradient-", "direction-"].contains { id.hasPrefix($0) }
        let toggle = app.buttons[magic ? "show-magic" : "show-colors"]
        if toggle.exists { toggle.tap() }
        _ = element.waitForExistence(timeout: 3)
        return element
    }

    /// Picks a palette color from the tray, or from All colors when it is not one of the tray's colors.
    private func pickColor(_ id: Int, in app: XCUIApplication) {
        let swatch = show("color-\(id)", in: app)
        if swatch.exists {
            swatch.tap()
            return
        }
        app.buttons["all-colors"].tap()
        app.buttons["all-color-\(id)"].tap()
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
