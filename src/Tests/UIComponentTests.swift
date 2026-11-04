import XCTest
import SwiftUI
@testable import AssessYourselfCore

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

@MainActor
private func renderInHost<V: View>(_ view: V, width: CGFloat = 375, height: CGFloat = 667) -> CGSize {
    let wrapped = view.environment(\.appTheme, AppTheme.standard)
    let hostingView = NSHostingView(rootView: wrapped)
    hostingView.frame = CGRect(x: 0, y: 0, width: width, height: height)
    hostingView.layout()
    return hostingView.fittingSize
}
#elseif canImport(UIKit)
import UIKit

@MainActor
private func renderInHost<V: View>(_ view: V, width: CGFloat = 375, height: CGFloat = 667) -> CGSize {
    let wrapped = view.environment(\.appTheme, AppTheme.standard)
    let controller = UIHostingController(rootView: wrapped)
    controller.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
    controller.view.layoutIfNeeded()
    return controller.view.intrinsicContentSize
}
#else
private func renderInHost<V: View>(_ view: V, width: CGFloat = 375, height: CGFloat = 667) -> CGSize {
    return CGSize(width: width, height: height)
}
#endif

@MainActor
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

        let selectedButton = ChoiceOptionButton(
            option: option,
            isSelected: true,
            dimensionId: "platform",
            onSelect: { selected = true }
        )

        XCTAssertEqual(selectedButton.option.id, "opt-1")
        XCTAssertTrue(selectedButton.isSelected)
        XCTAssertEqual(selectedButton.dimensionId, "platform")

        // Trigger onSelect callback
        selectedButton.onSelect()
        XCTAssertTrue(selected)

        // Render in hosting hierarchy (resolves @Environment and executes layout)
        let selectedSize = renderInHost(selectedButton)
        XCTAssertGreaterThan(selectedSize.height, 0)

        // Unselected button with nil dimension (fallback styling)
        let unselectedButton = ChoiceOptionButton(
            option: ChoiceOption(id: "opt-2", title: "Legacy Objective-C", scoreWeight: 30.0),
            isSelected: false,
            dimensionId: nil,
            onSelect: {}
        )
        let unselectedSize = renderInHost(unselectedButton)
        XCTAssertGreaterThan(unselectedSize.height, 0)
    }

    // MARK: - MultiSelectChipGrid Tests

    func testMultiSelectChipGridExecution() {
        let options = [
            ChoiceOption(id: "opt-1", title: "Git Workflows & Trunk Based Development", scoreWeight: 50.0),
            ChoiceOption(id: "opt-2", title: "CI/CD Automatisierung via GitHub Actions", scoreWeight: 50.0),
            ChoiceOption(id: "opt-3", title: "TDD & XCTest Unit Test Suite", scoreWeight: 50.0),
            ChoiceOption(id: "opt-4", title: "Instruments Profiling & Leaks Analysis", scoreWeight: 50.0)
        ]

        var toggledId: String?
        let grid = MultiSelectChipGrid(
            options: options,
            selectedIds: ["opt-1", "opt-2"],
            minSelectCount: 1,
            maxSelectCount: 3,
            dimensionId: "agile",
            onToggle: { toggledId = $0 }
        )

        XCTAssertEqual(grid.options.count, 4)
        XCTAssertEqual(grid.selectedIds.count, 2)
        XCTAssertEqual(grid.minSelectCount, 1)
        XCTAssertEqual(grid.maxSelectCount, 3)

        grid.onToggle("opt-3")
        XCTAssertEqual(toggledId, "opt-3")

        // Render in host view: forces ForEach evaluation of both selected and unselected chips
        let normalSize = renderInHost(grid)
        XCTAssertGreaterThan(normalSize.height, 0)

        // Exercise statusText branch: minSelect == maxSelect
        let exactGrid = MultiSelectChipGrid(
            options: options,
            selectedIds: ["opt-1"],
            minSelectCount: 2,
            maxSelectCount: 2,
            onToggle: { _ in }
        )
        _ = renderInHost(exactGrid)

        // Exercise statusText branch: minSelect == 1 (default)
        let defaultMinGrid = MultiSelectChipGrid(
            options: options,
            selectedIds: [],
            minSelectCount: 1,
            maxSelectCount: 3,
            onToggle: { _ in }
        )
        _ = renderInHost(defaultMinGrid)

        // Exercise statusText branch: minSelect > 1 and minSelect < maxSelect
        let rangeGrid = MultiSelectChipGrid(
            options: options,
            selectedIds: ["opt-1"],
            minSelectCount: 2,
            maxSelectCount: 3,
            dimensionId: "architecture",
            onToggle: { _ in }
        )
        _ = renderInHost(rangeGrid)

        // Exercise bounds: out of bounds (0 selected when min is 2)
        XCTAssertEqual(rangeGrid.selectedIds.count, 1)
    }

    func testMultiSelectChipGridDynamicTypeAndAccessibility() {
        let options = [
            ChoiceOption(id: "c1", title: "Sehr langer Text für Barrierefreiheitsprüfung im Grid", scoreWeight: 10.0),
            ChoiceOption(id: "c2", title: "Kurzer Text", scoreWeight: 10.0)
        ]

        let grid = MultiSelectChipGrid(
            options: options,
            selectedIds: ["c1"],
            minSelectCount: 1,
            maxSelectCount: 2,
            dimensionId: "quality",
            onToggle: { _ in }
        )

        // Render with standard size category on narrow screen
        let standardSize = renderInHost(
            grid.environment(\.sizeCategory, .medium),
            width: 320,
            height: 600
        )

        // Render with extra large accessibility dynamic type
        let largeTextSize = renderInHost(
            grid.environment(\.sizeCategory, .accessibilityExtraExtraLarge),
            width: 320, // narrow screen
            height: 600
        )
        XCTAssertGreaterThan(standardSize.height, 0)
        XCTAssertGreaterThan(largeTextSize.height, 0)
        XCTAssertGreaterThanOrEqual(largeTextSize.height, standardSize.height, "Accessibility Extra Extra Large font must expand or equal the layout height")
    }

    // MARK: - LikertSliderCard Tests

    func testLikertSliderCardExecution() {
        var changedValue: Double = 0.0

        let slider = LikertSliderCard(
            value: 4.0,
            minVal: 1.0,
            maxVal: 5.0,
            step: 1.0,
            minLabel: "Stimme überhaupt nicht zu",
            maxLabel: "Stimme voll und ganz zu",
            dimensionId: "quality",
            onValueChange: { changedValue = $0 }
        )

        XCTAssertEqual(slider.value, 4.0)
        XCTAssertEqual(slider.minVal, 1.0)
        XCTAssertEqual(slider.maxVal, 5.0)
        XCTAssertEqual(slider.step, 1.0)
        XCTAssertEqual(slider.minLabel, "Stimme überhaupt nicht zu")
        XCTAssertEqual(slider.maxLabel, "Stimme voll und ganz zu")

        slider.onValueChange(5.0)
        XCTAssertEqual(changedValue, 5.0)

        // Render in host view
        let size = renderInHost(slider)
        XCTAssertGreaterThan(size.height, 0)

        // Slider with nil dimension
        let plainSlider = LikertSliderCard(
            value: 2.0,
            minVal: 1.0,
            maxVal: 5.0,
            step: 1.0,
            minLabel: "Min",
            maxLabel: "Max",
            dimensionId: nil,
            onValueChange: { _ in }
        )
        _ = renderInHost(plainSlider)
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

        // Render in host view (within bounds -> success milestone)
        let normalSize = renderInHost(card)
        XCTAssertGreaterThan(normalSize.height, 0)

        // Exercise short text (< min -> warning state)
        let shortCard = ShortTextPromptCard(
            text: "Zu kurz",
            minCharacters: 15,
            maxCharacters: 200,
            dimensionId: nil,
            onTextChange: { _ in }
        )
        _ = renderInHost(shortCard)

        // Exercise text exceeding max (> max -> error state)
        let longText = String(repeating: "Wort ", count: 60)
        let longCard = ShortTextPromptCard(
            text: longText,
            minCharacters: 15,
            maxCharacters: 50,
            dimensionId: "quality",
            onTextChange: { _ in }
        )
        _ = renderInHost(longCard)

        // Exercise empty text (placeholder visible with full opacity)
        let emptyCard = ShortTextPromptCard(
            text: "",
            minCharacters: 10,
            maxCharacters: 100,
            onTextChange: { _ in }
        )
        _ = renderInHost(emptyCard)
    }

    // MARK: - ComponentShowcaseView Tests

    func testComponentShowcaseViewExecutionOnPhoneAndPad() {
        let showcase = ComponentShowcaseView()

        // Phone size (compact)
        let phoneSize = renderInHost(showcase, width: 393, height: 852)
        XCTAssertGreaterThan(phoneSize.height, 0)

        // iPad size (regular, testing 640pt max container layout)
        let padSize = renderInHost(showcase, width: 810, height: 1080)
        XCTAssertGreaterThan(padSize.height, 0)
    }

    // MARK: - AssessmentQuestionContainerView & AssessmentFlowView Tests

    func testAssessmentQuestionContainerViewWithAllQuestionTypes() {
        let vm = AssessmentViewModel()
        vm.loadCatalog()

        guard let catalog = vm.catalog else {
            XCTFail("Catalog required")
            return
        }

        // 1. Single Choice question rendering
        if let scQ = catalog.questions.first(where: { $0.type == .singleChoice }) {
            let container = AssessmentQuestionContainerView(viewModel: vm, question: scQ)
            let size = renderInHost(container)
            XCTAssertGreaterThan(size.height, 0)

            // With recorded answer
            let optId = scQ.options?.first?.id ?? "sc-1"
            vm.recordSingleChoice(questionId: scQ.id, selectedOptionId: optId)
            let answeredSize = renderInHost(container)
            XCTAssertGreaterThan(answeredSize.height, 0)
        }

        // 2. Multiple Choice question rendering
        if let mcQ = catalog.questions.first(where: { $0.type == .multipleChoice }) {
            let container = AssessmentQuestionContainerView(viewModel: vm, question: mcQ)
            let size = renderInHost(container)
            XCTAssertGreaterThan(size.height, 0)

            if let optId = mcQ.options?.first?.id {
                vm.toggleMultipleChoice(questionId: mcQ.id, optionId: optId)
            }
            let answeredSize = renderInHost(container)
            XCTAssertGreaterThan(answeredSize.height, 0)
        }

        // 3. Stepped Slider question rendering
        if let sliderQ = catalog.questions.first(where: { $0.type == .likertSlider }) {
            let container = AssessmentQuestionContainerView(viewModel: vm, question: sliderQ)
            let size = renderInHost(container)
            XCTAssertGreaterThan(size.height, 0)

            vm.recordSliderValue(questionId: sliderQ.id, value: 3.0)
            let answeredSize = renderInHost(container)
            XCTAssertGreaterThan(answeredSize.height, 0)
        }

        // 4. Short Text question rendering
        if let textQ = catalog.questions.first(where: { $0.type == .shortText }) {
            let container = AssessmentQuestionContainerView(viewModel: vm, question: textQ)
            let size = renderInHost(container)
            XCTAssertGreaterThan(size.height, 0)

            vm.recordShortText(questionId: textQ.id, text: "Ausführliche Reflexion über Softwarearchitektur und Codequalität.")
            let answeredSize = renderInHost(container)
            XCTAssertGreaterThan(answeredSize.height, 0)
        }
    }

    func testAssessmentFlowViewExecutionAcrossAllSessionStates() {
        let vm = AssessmentViewModel()

        // 1. Idle state
        let idleFlow = AssessmentFlowView(viewModel: vm)
        let idleSize = renderInHost(idleFlow)
        XCTAssertGreaterThan(idleSize.height, 0)

        // 2. In progress state
        vm.loadCatalog()
        let inProgressFlow = AssessmentFlowView(viewModel: vm)
        let progSize = renderInHost(inProgressFlow)
        XCTAssertGreaterThan(progSize.height, 0)

        // 3. Completed state
        // Answer all questions quickly to reach completed state
        if let questions = vm.catalog?.questions {
            for q in questions {
                switch q.type {
                case .singleChoice:
                    let optId = q.options?.first?.id ?? "sc"
                    vm.recordSingleChoice(questionId: q.id, selectedOptionId: optId)
                case .multipleChoice:
                    let optId = q.options?.first?.id ?? "mc"
                    vm.toggleMultipleChoice(questionId: q.id, optionId: optId)
                case .likertSlider:
                    vm.recordSliderValue(questionId: q.id, value: q.sliderDefault ?? 3.0)
                case .shortText:
                    vm.recordShortText(questionId: q.id, text: "Lang genug formulierte Antwort für die Vollständigkeit.")
                }
            }
            vm.submitAssessment()
            let completedFlow = AssessmentFlowView(viewModel: vm)
            let completedSize = renderInHost(completedFlow)
            XCTAssertGreaterThan(completedSize.height, 0)
        }

        // 4. Error state
        struct MockErrorLoader: CatalogLoaderProtocol {
            func loadBundledCatalog() throws -> AssessmentCatalog {
                throw CatalogLoaderError.resourceNotFound(name: "test.json")
            }
            func loadCatalog(from fileURL: URL) throws -> AssessmentCatalog {
                throw CatalogLoaderError.resourceNotFound(name: "test.json")
            }
            func decodeCatalog(from data: Data) throws -> AssessmentCatalog {
                throw CatalogLoaderError.jsonDecodingFailed(underlying: "Err")
            }
        }
        let errorVM = AssessmentViewModel(catalogLoader: MockErrorLoader())
        errorVM.loadCatalog()
        let errorFlow = AssessmentFlowView(viewModel: errorVM)
        let errorSize = renderInHost(errorFlow)
        XCTAssertGreaterThan(errorSize.height, 0)
    }

    func testTactileButtonStyleExecution() {
        let defaultStyle = TactileButtonStyle()
        let customStyle = TactileButtonStyle(pressedScale: 0.95, pressedOpacity: 0.85)

        let btn1 = Button("Default") {}.buttonStyle(defaultStyle)
        let btn2 = Button("Custom") {}.buttonStyle(customStyle)
        let btn3 = Button("Modifier") {}.tactileFeedback(scale: 0.96)

        let s1 = renderInHost(btn1)
        let s2 = renderInHost(btn2)
        let s3 = renderInHost(btn3)

        XCTAssertGreaterThan(s1.width, 0)
        XCTAssertGreaterThan(s2.width, 0)
        XCTAssertGreaterThan(s3.width, 0)
    }
}
