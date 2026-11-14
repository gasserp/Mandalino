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
        app.buttons["color-10"].tap()
        app.switches["sparkle"].tap()
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
        XCTAssertTrue(app.switches["sparkle"].isHittable)
        XCTAssertTrue(app.buttons["color-19"].isHittable)
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
        XCTAssertTrue(app.switches["sparkle"].isHittable)
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
        app.buttons["mix-colors"].tap()
        XCTAssertTrue(app.staticTexts["Farben mischen"].waitForExistence(timeout: 5))
        app.buttons["mix-color-10"].tap()
        app.buttons["mix-color-4"].tap()
        XCTAssertTrue(app.buttons["use-mixed-color"].isHittable)
        screenshot("German color mixer")
        app.buttons["use-mixed-color"].tap()
        let canvas = app.descendants(matching: .any)["drawing-canvas"]
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.switches["sparkle"].tap()
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

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
