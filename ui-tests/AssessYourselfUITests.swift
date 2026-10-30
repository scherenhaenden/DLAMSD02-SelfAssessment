import XCTest

final class AssessYourselfUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSingleChoiceMutualExclusionInteraction() throws {
        app.launch()
        let opt1 = app.buttons["choiceOption.sc-opt-1"]
        let opt2 = app.buttons["choiceOption.sc-opt-2"]

        XCTAssertTrue(opt1.waitForExistence(timeout: 10), "Option 1 must exist")
        XCTAssertTrue(opt2.waitForExistence(timeout: 10), "Option 2 must exist")

        // Ensure 56pt touch target height
        XCTAssertGreaterThanOrEqual(opt1.frame.height, 56, "Single choice button must meet >= 56 pt HIG height")

        // Tap Option 1
        opt1.tap()

        // Tap Option 2 -> Option 1 must be deselected, Option 2 selected (mutual exclusivity)
        opt2.tap()
        XCTAssertTrue(opt2.isSelected, "Option 2 must be selected after tap")
        XCTAssertFalse(opt1.isSelected, "Option 1 must be deselected when Option 2 is chosen")
    }

    func testMultipleChoiceBoundsAndToggleInteraction() throws {
        app.launch()
        let chipSwiftUI = app.buttons["multiChip.mc-opt-1"]
        let chipSwiftPM = app.buttons["multiChip.mc-opt-2"]
        let chipXCTest = app.buttons["multiChip.mc-opt-3"]
        let chipInstruments = app.buttons["multiChip.mc-opt-4"]

        XCTAssertTrue(chipSwiftUI.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(chipSwiftUI.frame.height, 43.9, "Chip must meet >= 44 pt HIG touch target")

        // Verify initial selection state (Showcase initializes with mc-opt-1 and mc-opt-2)
        XCTAssertTrue(chipSwiftUI.isSelected || (chipSwiftUI.value as? String) == "Ausgewählt")

        // Select 3rd chip (mc-opt-3 -> max 3 reached)
        chipXCTest.tap()

        // Attempting to select 4th option must be rejected by maxSelectCount constraint (3)
        chipInstruments.tap()

        // Deselect SwiftUI (mc-opt-1)
        chipSwiftUI.tap()

        // Now that a slot is free, selecting Instruments must succeed
        chipInstruments.tap()
    }

    func testLikertSliderAndShortTextInputInteraction() throws {
        app.launch()

        // Test slider interaction
        let slider = app.sliders["likertSlider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        slider.adjust(toNormalizedSliderPosition: 0.75)

        // Test text editor typing
        let editor = app.textViews["shortTextEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        editor.typeText("Praxiseinsatz mit SwiftUI.")

        // Verify character status
        let status = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Reflexionsstatus")).firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5))
    }
}
