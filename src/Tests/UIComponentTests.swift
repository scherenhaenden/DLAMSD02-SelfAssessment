import XCTest
import SwiftUI
@testable import AssessYourselfCore

final class UIComponentTests: XCTestCase {
    var theme: AppThemeProtocol!

    override func setUp() {
        super.setUp()
        theme = AppTheme.standard
    }

    override func tearDown() {
        theme = nil
        super.tearDown()
    }

    // MARK: - ChoiceOptionButton Tests

    func testChoiceOptionButtonExecution() {
        let option = ChoiceOption(id: "opt-1", title: "Swift Protocol Extension", scoreWeight: 100.0)
        var selected = false

        let button = ChoiceOptionButton(
            option: option,
            isSelected: true,
            dimensionId: "platform",
            onSelect: { selected = true }
        )

        XCTAssertEqual(button.option.id, "opt-1")
        XCTAssertTrue(button.isSelected)
        XCTAssertEqual(button.dimensionId, "platform")

        // Trigger onSelect callback
        button.onSelect()
        XCTAssertTrue(selected)

        // Exercise View body
        _ = button.body
    }

    // MARK: - MultiSelectChipGrid Tests

    func testMultiSelectChipGridExecution() {
        let options = [
            ChoiceOption(id: "opt-1", title: "Git", scoreWeight: 50.0),
            ChoiceOption(id: "opt-2", title: "CI/CD", scoreWeight: 50.0),
            ChoiceOption(id: "opt-3", title: "TDD", scoreWeight: 50.0)
        ]

        var toggledId: String?
        let grid = MultiSelectChipGrid(
            options: options,
            selectedIds: ["opt-1", "opt-2"],
            minSelectCount: 1,
            maxSelectCount: 2,
            dimensionId: "agile",
            onToggle: { toggledId = $0 }
        )

        XCTAssertEqual(grid.options.count, 3)
        XCTAssertEqual(grid.selectedIds.count, 2)
        XCTAssertEqual(grid.minSelectCount, 1)
        XCTAssertEqual(grid.maxSelectCount, 2)

        grid.onToggle("opt-3")
        XCTAssertEqual(toggledId, "opt-3")

        // Exercise View body
        _ = grid.body

        // Exercise statusText branch: minSelect == maxSelect
        let exactGrid = MultiSelectChipGrid(
            options: options,
            selectedIds: ["opt-1"],
            minSelectCount: 2,
            maxSelectCount: 2,
            onToggle: { _ in }
        )
        _ = exactGrid.body

        // Exercise statusText branch: minSelect == 1 (default)
        let defaultMinGrid = MultiSelectChipGrid(
            options: options,
            selectedIds: [],
            minSelectCount: 1,
            maxSelectCount: 3,
            onToggle: { _ in }
        )
        _ = defaultMinGrid.body

        // Exercise statusText branch: minSelect > 1 and minSelect < maxSelect
        let rangeGrid = MultiSelectChipGrid(
            options: options,
            selectedIds: ["opt-1"],
            minSelectCount: 2,
            maxSelectCount: 3,
            dimensionId: "architecture",
            onToggle: { _ in }
        )
        _ = rangeGrid.body
    }

    // MARK: - ComponentShowcaseView Tests

    func testComponentShowcaseViewExecution() {
        let showcase = ComponentShowcaseView()
        _ = showcase.body
    }

    // MARK: - LikertSliderCard Tests

    func testLikertSliderCardExecution() {
        var changedValue: Double = 0.0

        let slider = LikertSliderCard(
            value: 4.0,
            minVal: 1.0,
            maxVal: 5.0,
            step: 1.0,
            minLabel: "Nie",
            maxLabel: "Immer",
            dimensionId: "quality",
            onValueChange: { changedValue = $0 }
        )

        XCTAssertEqual(slider.value, 4.0)
        XCTAssertEqual(slider.minVal, 1.0)
        XCTAssertEqual(slider.maxVal, 5.0)
        XCTAssertEqual(slider.step, 1.0)
        XCTAssertEqual(slider.minLabel, "Nie")
        XCTAssertEqual(slider.maxLabel, "Immer")

        slider.onValueChange(5.0)
        XCTAssertEqual(changedValue, 5.0)

        // Exercise View body
        _ = slider.body
    }

    // MARK: - ShortTextPromptCard Tests

    func testShortTextPromptCardExecution() {
        var updatedText: String = ""

        let card = ShortTextPromptCard(
            text: "Architektur mit Clean Design und TDD.",
            minCharacters: 15,
            maxCharacters: 200,
            placeholder: "Schreibe etwas...",
            dimensionId: "architecture",
            onTextChange: { updatedText = $0 }
        )

        XCTAssertEqual(card.minCharacters, 15)
        XCTAssertEqual(card.maxCharacters, 200)
        XCTAssertEqual(card.placeholder, "Schreibe etwas...")

        card.onTextChange("Neuer Text für Testlauf.")
        XCTAssertEqual(updatedText, "Neuer Text für Testlauf.")

        // Exercise View body
        _ = card.body

        // Exercise with short text (< min)
        let shortCard = ShortTextPromptCard(
            text: "Zu kurz",
            minCharacters: 15,
            maxCharacters: 200,
            onTextChange: { _ in }
        )
        _ = shortCard.body

        // Exercise with text exceeding max
        let longText = String(repeating: "Wort ", count: 60)
        let longCard = ShortTextPromptCard(
            text: longText,
            minCharacters: 15,
            maxCharacters: 50,
            onTextChange: { _ in }
        )
        _ = longCard.body
    }
}
