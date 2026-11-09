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
            XCTAssertEqual(bar.label, "\(title): \(String(format: "%.1f %%", expectedScore))")
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

    // MARK: - Sprint 7: History View Navigation & State

    func testHistoryTabShowsEmptyStateAndNavigation() throws {
        app.launch()
        let historyTab = app.tabBars.buttons["Verlauf"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 5), "Verlauf tab must exist in root navigation")
        historyTab.tap()

        // If history already contains items (e.g. from an earlier persistent test run), clear it
        let clearButton = app.buttons["history.clearButton"]
        if clearButton.waitForExistence(timeout: 2) {
            clearButton.tap()
            let confirmAlertButton = app.alerts.buttons["Löschen"]
            if confirmAlertButton.waitForExistence(timeout: 2) {
                confirmAlertButton.tap()
            }
        }

        // Verify empty state is displayed
        let emptyState = app.descendants(matching: .any)["history.emptyState"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5), "Empty state label must be displayed when no assessments exist")

        // Switch back to Assessment tab
        let assessmentTab = app.tabBars.buttons["Assessment"]
        XCTAssertTrue(assessmentTab.waitForExistence(timeout: 3))
        assessmentTab.tap()

        let welcomeTitle = app.staticTexts["flow.welcomeTitle"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5), "Returning to assessment tab must restore flow")
    }

    // MARK: - Sprint 8 Acceptance: History Persistence & Corruption Recovery Scenarios

    private func completeFullAssessmentFlow() {
        switchToAssessmentTabIfNeeded()

        let startButton = app.buttons["flow.startButton"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
        }

        let counterPill = app.staticTexts["flow.counterPill"]
        XCTAssertTrue(counterPill.waitForExistence(timeout: 10))

        let nextButton = app.buttons["flow.nextButton"]
        let submitButton = app.buttons["flow.submitButton"]

        for questionNumber in 1...24 {
            let qExpectation = expectation(for: NSPredicate(format: "label == 'Frage \(questionNumber) / 24'"), evaluatedWith: counterPill)
            wait(for: [qExpectation], timeout: 5)

            let scOptions = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'choiceOption.'"))
            let mcChips = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'multiChip.'"))
            let slider = app.sliders["likertSlider"]
            let editor = app.textViews["shortTextEditor"]

            if scOptions.count > 0 {
                scOptions.element(boundBy: 0).tap()
            } else if mcChips.count > 0 {
                mcChips.element(boundBy: 0).tap()
            } else if slider.exists {
                slider.adjust(toNormalizedSliderPosition: 0.75)
            } else if editor.exists {
                editor.tap()
                editor.typeText("Modulare Entkopplung mit Swift Protocols und sauberer Dependency Injection.")
            }

            if questionNumber < 24 {
                XCTAssertTrue(nextButton.waitForExistence(timeout: 3))
                XCTAssertTrue(nextButton.isEnabled)
                nextButton.tap()
            } else {
                XCTAssertTrue(submitButton.waitForExistence(timeout: 3))
                XCTAssertTrue(submitButton.isEnabled)
                submitButton.tap()
            }
        }

        let completionHeadline = app.staticTexts["Self-Assessment abgeschlossen!"]
        XCTAssertTrue(completionHeadline.waitForExistence(timeout: 10))
    }

    func testAssessmentPersistenceSurvivesRelaunchInHistory() throws {
        // Step 1: Clean launch, complete assessment & submit
        app.launchArguments = ["--uitesting", "--uitesting-reset-history"]
        app.launch()

        completeFullAssessmentFlow()

        // Step 2: Navigate to Verlauf tab and verify the assessment card exists
        let historyTab = app.tabBars.buttons["Verlauf"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 5), "Verlauf tab must exist")
        historyTab.tap()

        let countHeader = app.staticTexts["Verlauf (1)"]
        XCTAssertTrue(countHeader.waitForExistence(timeout: 5), "History count header must report exactly 1 record")
        XCTAssertTrue(app.staticTexts["Max. 50 Einträge (FIFO)"].exists)

        let clearButton = app.buttons["history.clearButton"]
        XCTAssertTrue(clearButton.exists, "Clear button must be available when history contains records")

        // Step 3: Terminate app and relaunch PRESERVING history store
        app.terminate()
        app.launchArguments = ["--uitesting", "--uitesting-preserve-history"]
        app.launch()

        let historyTabAfterRelaunch = app.tabBars.buttons["Verlauf"]
        XCTAssertTrue(historyTabAfterRelaunch.waitForExistence(timeout: 5))
        historyTabAfterRelaunch.tap()

        // Verify persisted record survived relaunch without duplication
        let countHeaderAfterRelaunch = app.staticTexts["Verlauf (1)"]
        XCTAssertTrue(countHeaderAfterRelaunch.waitForExistence(timeout: 5), "Relaunched app must retain exactly 1 record without duplication")

        // Step 4: Clear history with confirmation and verify empty state
        let clearButtonAfter = app.buttons["history.clearButton"]
        XCTAssertTrue(clearButtonAfter.waitForExistence(timeout: 3))
        clearButtonAfter.tap()

        let alertDelete = app.alerts.buttons["Löschen"]
        XCTAssertTrue(alertDelete.waitForExistence(timeout: 3))
        alertDelete.tap()

        let emptyState = app.descendants(matching: .any)["history.emptyState"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5), "Empty state must be displayed after confirming clear")
    }

    func testHistoryCorruptionRecoveryViaAlertAction() throws {
        // Launch with corrupted JSON data in storageKey
        app.launchArguments = ["--uitesting-corrupt-history"]
        app.launch()

        let historyTab = app.tabBars.buttons["Verlauf"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 5))
        historyTab.tap()

        // Verify error headline is displayed
        let errorTitle = app.staticTexts["Fehler beim Laden"]
        XCTAssertTrue(errorTitle.waitForExistence(timeout: 5), "Error headline must appear when store is corrupted")

        let retryButton = app.buttons["Erneut versuchen"]
        XCTAssertTrue(retryButton.waitForExistence(timeout: 5), "Retry button must exist")

        let resetCorruptedButton = app.buttons["Beschädigten Verlauf zurücksetzen"]
        XCTAssertTrue(resetCorruptedButton.waitForExistence(timeout: 5), "Reset corrupted button must exist")

        // Scenario A: User taps reset but cancels dialog -> error view remains
        resetCorruptedButton.tap()
        let alertCancel = app.alerts.buttons["Abbrechen"]
        XCTAssertTrue(alertCancel.waitForExistence(timeout: 5))
        alertCancel.tap()

        XCTAssertTrue(errorTitle.waitForExistence(timeout: 5), "Error title must persist when user cancels corruption reset")

        // Scenario B: User taps reset and confirms -> corrupted data is cleared, empty state appears
        resetCorruptedButton.tap()
        let alertReset = app.alerts.buttons["Zurücksetzen"]
        XCTAssertTrue(alertReset.waitForExistence(timeout: 5))
        alertReset.tap()

        let emptyState = app.descendants(matching: .any)["history.emptyState"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5), "Empty state must appear after confirming corrupted history reset")
    }

    // MARK: - Multi-Device & Ergonomics Acceptance (US-13, ADR-08)

    func testIPadAndMultiDeviceShowcaseLayoutErgonomics() throws {
        app.launch()
        switchToShowcaseTabIfNeeded()

        let showcaseTitle = app.staticTexts["Sprint 3 Component Showcase"]
        XCTAssertTrue(showcaseTitle.waitForExistence(timeout: 10))

        // Verify touch target ergonomics on primary interactive elements (HIG >= 44 pt)
        let singleChoiceButton = app.buttons["choiceOption.sc-opt-1"]
        XCTAssertTrue(singleChoiceButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(singleChoiceButton.frame.height, 44.0, "Touch target must meet HIG minimum 44 pt")

        let multiChipButton = app.buttons["multiChip.mc-opt-1"]
        XCTAssertTrue(multiChipButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(multiChipButton.frame.height, 44.0, "Touch target must meet HIG minimum 44 pt")

        // Switch to Assessment tab and verify start button touch target
        let assessmentTab = app.tabBars.buttons["Assessment"]
        XCTAssertTrue(assessmentTab.waitForExistence(timeout: 5))
        assessmentTab.tap()

        let startButton = app.buttons["flow.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(startButton.frame.height, 44.0, "Start button touch target must be >= 44 pt")
    }
}
