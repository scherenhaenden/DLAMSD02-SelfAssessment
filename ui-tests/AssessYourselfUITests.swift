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

    private func switchToShowcaseTabIfNeeded() {
        let showcaseTab = app.tabBars.buttons["Showcase"]
        if showcaseTab.waitForExistence(timeout: 3) {
            showcaseTab.tap()
        }
    }

    private func switchToAssessmentTabIfNeeded() {
        let assessmentTab = app.tabBars.buttons["Assessment"]
        if assessmentTab.waitForExistence(timeout: 3) {
            assessmentTab.tap()
        }
    }

    // MARK: - Sprint 4: Sequential Assessment Flow Tests

    func testWelcomeScreenRemainsVisibleUntilStartTapped() throws {
        app.launch()
        switchToAssessmentTabIfNeeded()

        // Verify welcome elements
        let welcomeTitle = app.staticTexts["flow.welcomeTitle"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5), "Welcome title must be visible upon launch")
        XCTAssertEqual(welcomeTitle.label, "Willkommen zum DevProfile Self-Assessment")

        let welcomeDesc = app.staticTexts["flow.welcomeDescription"]
        XCTAssertTrue(welcomeDesc.exists, "Welcome description must be visible")

        let startButton = app.buttons["flow.startButton"]
        XCTAssertTrue(startButton.exists, "Start button must be visible on welcome screen")

        // Counter pill and navigation buttons must NOT exist yet
        let counterPill = app.staticTexts["flow.counterPill"]
        XCTAssertFalse(counterPill.exists, "Question counter must not be visible before starting")

        // Tap start button to begin
        startButton.tap()

        // Now Question 1 must appear
        XCTAssertTrue(counterPill.waitForExistence(timeout: 5), "Question counter must appear after starting")
        XCTAssertEqual(counterPill.label, "Frage 1 / 24")
    }

    func testSequentialAssessmentFlowProgressionAndValidation() throws {
        app.launch()
        switchToAssessmentTabIfNeeded()

        // Welcome screen handling
        let startButton = app.buttons["flow.startButton"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
        }

        // 1. Initial State: Question 1 of 24 (Single Choice)
        let counterPill = app.staticTexts["flow.counterPill"]
        XCTAssertTrue(counterPill.waitForExistence(timeout: 10), "Counter pill must exist")
        XCTAssertEqual(counterPill.label, "Frage 1 / 24")

        let dimensionBadge = app.staticTexts["flow.dimensionBadge"]
        XCTAssertTrue(dimensionBadge.waitForExistence(timeout: 5))
        XCTAssertEqual(dimensionBadge.label, "Software Architecture & System Design")

        let backButton = app.buttons["flow.backButton"]
        let nextButton = app.buttons["flow.nextButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))

        // Back button must be disabled on first question
        XCTAssertFalse(backButton.isEnabled, "Back button must be disabled on question 1")
        // Next button must be disabled until question is answered
        XCTAssertFalse(nextButton.isEnabled, "Next button must be disabled before answering")

        // Select option for Question 1
        let sc1Options = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'choiceOption.'"))
        XCTAssertGreaterThan(sc1Options.count, 0, "Question 1 choice options must be present")
        sc1Options.element(boundBy: 0).tap()

        XCTAssertTrue(nextButton.isEnabled, "Next button must be enabled after answering Q1")
        nextButton.tap()

        // 2. Question 2 of 24 (Single Choice)
        let q2Expectation = expectation(for: NSPredicate(format: "label == 'Frage 2 / 24'"), evaluatedWith: counterPill)
        wait(for: [q2Expectation], timeout: 5)
        XCTAssertTrue(backButton.isEnabled, "Back button must be enabled on question 2")

        // Navigate back to Q1 and verify answer preservation
        backButton.tap()
        let q1BackExpectation = expectation(for: NSPredicate(format: "label == 'Frage 1 / 24'"), evaluatedWith: counterPill)
        wait(for: [q1BackExpectation], timeout: 5)
        XCTAssertTrue(nextButton.isEnabled, "Next button must remain enabled as Q1 answer was preserved")
        XCTAssertFalse(backButton.isEnabled, "Back button disabled on Q1")
        nextButton.tap()

        // Back on Question 2 -> Answer Q2
        let q2ReturnExpectation = expectation(for: NSPredicate(format: "label == 'Frage 2 / 24'"), evaluatedWith: counterPill)
        wait(for: [q2ReturnExpectation], timeout: 5)
        let sc2Options = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'choiceOption.'"))
        sc2Options.element(boundBy: 0).tap()
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

        // 3. Question 3 of 24 (Multiple Choice: arch-mc-01)
        let q3Expectation = expectation(for: NSPredicate(format: "label == 'Frage 3 / 24'"), evaluatedWith: counterPill)
        wait(for: [q3Expectation], timeout: 5)

        let mcChips = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'multiChip.'"))
        XCTAssertGreaterThanOrEqual(mcChips.count, 3, "Multiple choice chips must be visible")

        // Initially no chips selected -> Next disabled
        XCTAssertFalse(nextButton.isEnabled)

        // Select 2 chips
        mcChips.element(boundBy: 0).tap()
        mcChips.element(boundBy: 1).tap()
        XCTAssertTrue(nextButton.isEnabled, "Next must be enabled after selecting MC chips within bounds")
        nextButton.tap()

        // 4. Question 4 of 24 (Likert Slider: arch-lk-01)
        let q4Expectation = expectation(for: NSPredicate(format: "label == 'Frage 4 / 24'"), evaluatedWith: counterPill)
        wait(for: [q4Expectation], timeout: 5)

        let slider = app.sliders["likertSlider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        // Default 3.0 auto-synced via onAppear -> Next is enabled immediately without forced wiggling
        XCTAssertTrue(nextButton.isEnabled, "Next must be valid with synced default slider score")

        // Adjust slider to verify interaction
        slider.adjust(toNormalizedSliderPosition: 0.75)
        nextButton.tap()

        // 5. Question 5 of 24 (Likert Slider: arch-lk-02)
        let q5Expectation = expectation(for: NSPredicate(format: "label == 'Frage 5 / 24'"), evaluatedWith: counterPill)
        wait(for: [q5Expectation], timeout: 5)
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

        // 6. Question 6 of 24 (Short Text: arch-tx-01)
        let q6Expectation = expectation(for: NSPredicate(format: "label == 'Frage 6 / 24'"), evaluatedWith: counterPill)
        wait(for: [q6Expectation], timeout: 5)

        let editor = app.textViews["shortTextEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertFalse(nextButton.isEnabled, "Next must be disabled before typing required short text")

        editor.tap()
        let sampleReflection = "Modulare Clean Architecture mit SPM und Swift."
        for char in sampleReflection {
            editor.typeText(String(char))
            Thread.sleep(forTimeInterval: 0.03)
        }

        XCTAssertTrue(nextButton.isEnabled, "Next must be enabled once min characters are fulfilled")
        nextButton.tap()

        // 7. Question 7 of 24 (Dimension Transition: Swift & Apple Platform Engineering)
        let q7Expectation = expectation(for: NSPredicate(format: "label == 'Frage 7 / 24'"), evaluatedWith: counterPill)
        wait(for: [q7Expectation], timeout: 5)
        XCTAssertEqual(dimensionBadge.label, "Swift & Apple Platform Engineering", "Dimension badge must transition smoothly")
    }

    func testCompleteFull24QuestionAssessmentFlowAndVerifyCompletion() throws {
        app.launch()
        switchToAssessmentTabIfNeeded()

        let startButton = app.buttons["flow.startButton"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
        }

        let counterPill = app.staticTexts["flow.counterPill"]
        XCTAssertTrue(counterPill.waitForExistence(timeout: 10))

        let nextButton = app.buttons["flow.nextButton"]
        let submitButton = app.buttons["flow.submitButton"]

        var observedPoints: [Int: Double] = [:]

        // Traverse all 24 questions
        for questionNumber in 1...24 {
            let qExpectation = expectation(for: NSPredicate(format: "label == 'Frage \(questionNumber) / 24'"), evaluatedWith: counterPill)
            wait(for: [qExpectation], timeout: 5)

            // Answer based on polymorphic question component
            let scOptions = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'choiceOption.'"))
            let mcChips = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'multiChip.'"))
            let slider = app.sliders["likertSlider"]
            let editor = app.textViews["shortTextEditor"]

            if scOptions.count > 0 {
                scOptions.element(boundBy: 0).tap()
                observedPoints[questionNumber] = 100.0
            } else if mcChips.count > 0 {
                mcChips.element(boundBy: 0).tap()
                observedPoints[questionNumber] = 25.0
            } else if slider.exists {
                slider.adjust(toNormalizedSliderPosition: 0.75)
                let observedBadge = app.staticTexts["likertSlider.scoreBadge"].label
                let observedValue = Double(observedBadge.components(separatedBy: "/")[0].trimmingCharacters(in: .whitespaces)) ?? 4.0
                observedPoints[questionNumber] = (observedValue - 1.0) / 4.0 * 100.0
            } else if editor.exists {
                editor.tap()
                let reflection = "Modulare Entkopplung mit Swift Protocols und sauberer Dependency Injection."
                editor.typeText(reflection)
                let observedText = editor.value as? String ?? reflection
                let tokens = Set(observedText.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
                let keywords: Set<String> = [
                    "swift", "swiftui", "protocol", "protokoll", "mvvm", "viewmodel", "combine",
                    "test", "xctest", "coverage", "llvm", "invariant", "schichten", "architektur",
                    "entkopplung", "git", "commit", "sprint", "refactoring", "boundary", "rollback"
                ]
                observedPoints[questionNumber] = 60.0 + 10.0 * Double(min(4, tokens.intersection(keywords).count))
            }

            if questionNumber < 24 {
                XCTAssertTrue(nextButton.waitForExistence(timeout: 3))
                XCTAssertTrue(nextButton.isEnabled, "Next button must be enabled for question \(questionNumber)")
                nextButton.tap()
            } else {
                XCTAssertTrue(submitButton.waitForExistence(timeout: 3))
                XCTAssertTrue(submitButton.isEnabled, "Submit button must be enabled on question 24")
                submitButton.tap()
            }
        }

        // Verify completion screen
        let completionHeadline = app.staticTexts["Self-Assessment abgeschlossen!"]
        XCTAssertTrue(completionHeadline.waitForExistence(timeout: 10), "Completion headline must appear")

        let archetypeLabel = app.staticTexts["Diagnostizierter Archetyp"]
        XCTAssertTrue(archetypeLabel.waitForExistence(timeout: 5), "Archetype diagnosis label must be visible")

        // Permanent integrated verification of the 4 dimension competency score bars
        let dimensions = [
            ("architecture", "Software Architecture & System Design"),
            ("platform", "Swift & Apple Platform Engineering"),
            ("quality", "Quality Assurance & Verification"),
            ("agile", "Agile Practices & Collaboration")
        ]
        var expectedScores: [Double] = []
        for (index, dimension) in dimensions.enumerated() {
            let (id, title) = dimension
            let points = ((index * 6 + 1)...(index * 6 + 6)).compactMap { observedPoints[$0] }
            let expectedScore = points.isEmpty ? 0.0 : (points.reduce(0, +) / Double(points.count))
            expectedScores.append(expectedScore)
            let bar = app.descendants(matching: .any).matching(identifier: "dimensionBar.\(id)").firstMatch
            XCTAssertTrue(bar.waitForExistence(timeout: 5), "Dimension score bar for \(id) must exist")
            XCTAssertEqual(bar.label, "\(title): \(String(format: "%.0f", expectedScore)) Prozent")
        }

        let expectedOverall = expectedScores.isEmpty ? 0.0 : (expectedScores.reduce(0, +) / Double(expectedScores.count))
        XCTAssertTrue(app.staticTexts[String(format: "%.1f %%", expectedOverall)].exists, "Overall score badge must match calculated average")

        // Scroll down to recommendations and reset action
        app.swipeUp()

        let recommendations = app.descendants(matching: .any).matching(identifier: "pedagogicalRecommendations").firstMatch
        XCTAssertTrue(recommendations.waitForExistence(timeout: 5), "Pedagogical recommendations section must exist")

        let resetButton = app.buttons["flow.resetButton"]
        if !resetButton.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5), "Reset button must exist on completion view")

        // Reset and verify return to Question 1
        resetButton.tap()
        let resetCounterExpectation = expectation(for: NSPredicate(format: "label == 'Frage 1 / 24'"), evaluatedWith: counterPill)
        wait(for: [resetCounterExpectation], timeout: 5)
    }

    // MARK: - Sprint 3 Atomic Component Verification Tests

    func testSingleChoiceMutualExclusionInteraction() throws {
        app.launch()
        switchToShowcaseTabIfNeeded()

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
        switchToShowcaseTabIfNeeded()

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
        switchToShowcaseTabIfNeeded()

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
