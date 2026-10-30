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
        let counterPill = app.staticTexts["multiChip.counterPill"]

        XCTAssertTrue(chipSwiftUI.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(chipSwiftUI.frame.height, 43.9, "Chip must meet >= 44 pt HIG touch target")
        XCTAssertTrue(counterPill.waitForExistence(timeout: 5))

        // 1. Initial State: mc-opt-1 and mc-opt-2 are pre-selected (2 of 3)
        XCTAssertTrue(chipSwiftUI.isSelected || (chipSwiftUI.value as? String) == "Ausgewählt")
        XCTAssertTrue(chipSwiftPM.isSelected || (chipSwiftPM.value as? String) == "Ausgewählt")
        XCTAssertFalse(chipXCTest.isSelected && (chipXCTest.value as? String) != "Nicht ausgewählt")
        XCTAssertFalse(chipInstruments.isSelected && (chipInstruments.value as? String) != "Nicht ausgewählt")
        XCTAssertEqual(counterPill.label, "2/3")

        // 2. Select 3rd chip (mc-opt-3: XCTest) -> Max selection of 3 reached
        chipXCTest.tap()
        XCTAssertTrue(chipXCTest.isSelected || (chipXCTest.value as? String) == "Ausgewählt")
        XCTAssertEqual(counterPill.label, "3/3")

        // 3. Attempting to select 4th option (mc-opt-4: Instruments) must be rejected by maxSelectCount (3)
        chipInstruments.tap()
        XCTAssertFalse(chipInstruments.isSelected && (chipInstruments.value as? String) != "Nicht ausgewählt")
        XCTAssertEqual(counterPill.label, "3/3", "Selection count must remain 3/3 when boundary cap is hit")

        // 4. Deselect SwiftUI (mc-opt-1) -> Frees one slot
        chipSwiftUI.tap()
        XCTAssertFalse(chipSwiftUI.isSelected && (chipSwiftUI.value as? String) != "Nicht ausgewählt")
        XCTAssertEqual(counterPill.label, "2/3", "Selection count must decrement to 2/3")

        // 5. Selecting Instruments now succeeds
        chipInstruments.tap()
        XCTAssertTrue(chipInstruments.isSelected || (chipInstruments.value as? String) == "Ausgewählt")
        XCTAssertEqual(counterPill.label, "3/3", "Selection count must return to 3/3")

        // 6. Deselect SwiftPM (mc-opt-2) and re-select to verify bidirectional toggle
        chipSwiftPM.tap()
        XCTAssertFalse(chipSwiftPM.isSelected && (chipSwiftPM.value as? String) != "Nicht ausgewählt")
        XCTAssertEqual(counterPill.label, "2/3")

        chipSwiftPM.tap()
        XCTAssertTrue(chipSwiftPM.isSelected || (chipSwiftPM.value as? String) == "Ausgewählt")
        XCTAssertEqual(counterPill.label, "3/3")
    }

    func testLikertSliderAndShortTextInputInteraction() throws {
        app.launch()

        // 1. Likert Slider initial state verification
        let slider = app.sliders["likertSlider"]
        let scoreBadge = app.staticTexts["likertSlider.scoreBadge"]
        let verbalAnchor = app.staticTexts["likertSlider.verbalAnchor"]

        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        XCTAssertTrue(scoreBadge.waitForExistence(timeout: 5))
        XCTAssertEqual(scoreBadge.label, "4 / 5", "Initial slider score must be 4 / 5")
        XCTAssertEqual(verbalAnchor.label, "Eher hoch", "Initial verbal anchor must be Eher hoch")

        // Adjust slider from 4.0 down to minimum 1.0 (normalized position 0.0)
        slider.adjust(toNormalizedSliderPosition: 0.0)

        // Verify that the slider value and score badge have genuinely changed
        XCTAssertEqual(scoreBadge.label, "1 / 5", "Score badge must update to 1 / 5 after dragging to minimum")
        XCTAssertEqual(verbalAnchor.label, "Sehr niedrig", "Verbal anchor must update to Sehr niedrig")

        // 2. Short Text Editor initial empty state verification
        let editor = app.textViews["shortTextEditor"]
        let status = app.staticTexts["shortTextStatus"]
        let placeholder = app.staticTexts["shortTextPlaceholder"]

        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(placeholder.waitForExistence(timeout: 5), "Placeholder must be visible in empty initial state")

        // Verify initial empty state character status and warning milestone
        XCTAssertTrue(status.label.contains("0 von maximal 250 Zeichen"), "Initial character count must be 0")
        XCTAssertTrue(status.label.contains("Noch 15 Zeichen bis zum Mindestumfang"), "Initial state must warn about minimum characters")

        // Type text into editor (wait for keyboard animation to settle)
        editor.tap()
        let keyboard = app.keyboards.firstMatch
        _ = keyboard.waitForExistence(timeout: 3)

        let expectedInput = "Praxiseinsatz mit SwiftUI."
        for char in expectedInput {
            editor.typeText(String(char))
            Thread.sleep(forTimeInterval: 0.05)
        }

        // Verify that typed text is present and matches the expected input exactly
        let editorText = (editor.value as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(editorText, expectedInput, "Editor must contain exact typed text")

        // Verify that placeholder has disappeared now that text is present
        XCTAssertFalse(placeholder.exists, "Placeholder must disappear when text is typed")

        // Verify that status bar unconditionally reflects the 26 characters and milestone is achieved
        let updatedStatus = app.staticTexts["shortTextStatus"]
        XCTAssertTrue(updatedStatus.waitForExistence(timeout: 5))
        XCTAssertTrue(updatedStatus.label.contains("\(expectedInput.count) von maximal 250 Zeichen"), "Status must report exact count")
        XCTAssertTrue(updatedStatus.label.contains("Mindestumfang erfüllt"), "Milestone must indicate requirement met unconditionally")
        XCTAssertEqual(updatedStatus.value as? String, "\(expectedInput.count) Zeichen", "Accessibility value must announce exact character count")
    }
}
