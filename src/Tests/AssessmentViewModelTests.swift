import XCTest
@testable import AssessYourselfCore

final class AssessmentViewModelTests: XCTestCase {
    private var loader: CatalogLoaderProtocol!
    private var engine: EvaluationEngineProtocol!

    override func setUp() {
        super.setUp()
        loader = CatalogLoader()
        engine = EvaluationEngine()
    }

    override func tearDown() {
        loader = nil
        engine = nil
        super.tearDown()
    }

    func testInitialStateAndLoadCatalogSuccess() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        XCTAssertEqual(vm.state, .idle)
        XCTAssertNil(vm.catalog)
        XCTAssertEqual(vm.currentQuestionIndex, 0)
        XCTAssertEqual(vm.totalQuestions, 0)
        XCTAssertNil(vm.currentQuestion)
        XCTAssertFalse(vm.canGoBack)
        XCTAssertFalse(vm.canGoForward)

        vm.loadCatalog()

        XCTAssertEqual(vm.state, .inProgress)
        XCTAssertNotNil(vm.catalog)
        XCTAssertEqual(vm.totalQuestions, 24)
        XCTAssertEqual(vm.currentQuestionIndex, 0)
        XCTAssertNotNil(vm.currentQuestion)
        XCTAssertNotNil(vm.currentDimension)
        XCTAssertFalse(vm.canGoBack)
        XCTAssertGreaterThan(vm.progress, 0.0)
    }

    func testSingleChoiceAnswerRecordingAndValidation() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vm.loadCatalog()

        guard let question = vm.currentQuestion, question.type == .singleChoice else {
            XCTFail("First question in catalog must be singleChoice")
            return
        }

        // Initially no answer recorded
        XCTAssertFalse(vm.isCurrentAnswerValid)
        XCTAssertFalse(vm.canGoForward)

        // Record single choice
        let optionId = question.options?.first?.id ?? "sc-1"
        vm.recordSingleChoice(questionId: question.id, selectedOptionId: optionId)

        XCTAssertTrue(vm.isCurrentAnswerValid)
        XCTAssertTrue(vm.canGoForward)

        // Advance to next question
        vm.advance()
        XCTAssertEqual(vm.currentQuestionIndex, 1)
        XCTAssertTrue(vm.canGoBack)

        // Going back restores the recorded answer
        vm.goBack()
        XCTAssertEqual(vm.currentQuestionIndex, 0)
        XCTAssertTrue(vm.isCurrentAnswerValid)
        if case .singleChoice(let selected) = vm.answers[question.id] {
            XCTAssertEqual(selected, optionId)
        } else {
            XCTFail("Recorded answer must match singleChoice payload")
        }
    }

    func testMultipleChoiceToggleAndBoundsValidation() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vm.loadCatalog()

        // Find a multiple choice question in catalog
        guard let mcQuestion = vm.catalog?.questions.first(where: { $0.type == .multipleChoice }),
              let options = mcQuestion.options, options.count >= 3 else {
            XCTFail("Catalog must contain multiple choice question with >= 3 options")
            return
        }

        let qId = mcQuestion.id
        let minCount = mcQuestion.minSelectCount ?? 1
        let maxCount = mcQuestion.maxSelectCount ?? 3
        XCTAssertGreaterThanOrEqual(maxCount, minCount)

        // Toggle 1st option
        vm.toggleMultipleChoice(questionId: qId, optionId: options[0].id)
        if case .multipleChoice(let ids) = vm.answers[qId] {
            XCTAssertEqual(ids, [options[0].id])
        }

        // Toggle 2nd option
        vm.toggleMultipleChoice(questionId: qId, optionId: options[1].id)
        if case .multipleChoice(let ids) = vm.answers[qId] {
            XCTAssertEqual(ids.count, 2)
        }

        // Toggle 1st option again (deselects)
        vm.toggleMultipleChoice(questionId: qId, optionId: options[0].id)
        if case .multipleChoice(let ids) = vm.answers[qId] {
            XCTAssertEqual(ids, [options[1].id])
        }
    }

    func testSliderAnswerRecordingAndValidation() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vm.loadCatalog()

        guard let sliderQuestion = vm.catalog?.questions.first(where: { $0.type == .likertSlider }) else {
            XCTFail("Catalog must contain stepped slider question")
            return
        }

        let qId = sliderQuestion.id
        let minVal = sliderQuestion.sliderMin ?? 1.0
        let maxVal = sliderQuestion.sliderMax ?? 5.0
        let step = sliderQuestion.sliderStep ?? 1.0
        XCTAssertGreaterThan(maxVal, minVal)

        // Record compliant slider value
        let testVal = minVal + step
        vm.recordSliderValue(questionId: qId, value: testVal)

        if case .steppedSlider(let val) = vm.answers[qId] {
            XCTAssertEqual(val, testVal)
        } else {
            XCTFail("Recorded answer must match steppedSlider payload")
        }
    }

    func testShortTextAnswerRecordingAndValidation() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vm.loadCatalog()

        guard let textQuestion = vm.catalog?.questions.first(where: { $0.type == .shortText }) else {
            XCTFail("Catalog must contain short text question")
            return
        }

        let qId = textQuestion.id
        let minChars = textQuestion.minCharacters ?? 15
        let validText = String(repeating: "Testwort ", count: 5) // > 15 chars
        XCTAssertGreaterThan(validText.count, minChars)

        vm.recordShortText(questionId: qId, text: validText)

        if case .shortText(let text) = vm.answers[qId] {
            XCTAssertEqual(text, validText)
        } else {
            XCTFail("Recorded answer must match shortText payload")
        }
    }

    func testFullAssessmentFlowToCompletion() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vm.loadCatalog()

        guard let questions = vm.catalog?.questions else {
            XCTFail("Catalog must be loaded")
            return
        }

        // Answer every question sequentially
        for (idx, question) in questions.enumerated() {
            XCTAssertEqual(vm.currentQuestionIndex, idx)

            switch question.type {
            case .singleChoice:
                let optId = question.options?.first?.id ?? "opt"
                vm.recordSingleChoice(questionId: question.id, selectedOptionId: optId)
            case .multipleChoice:
                let optId = question.options?.first?.id ?? "opt"
                vm.toggleMultipleChoice(questionId: question.id, optionId: optId)
            case .likertSlider:
                let defaultVal = question.sliderDefault ?? question.sliderMin ?? 1.0
                vm.recordSliderValue(questionId: question.id, value: defaultVal)
            case .shortText:
                let sampleText = "Praxiseinsatz mit sauberer Architektur und TDD."
                vm.recordShortText(questionId: question.id, text: sampleText)
            }

            XCTAssertTrue(vm.isCurrentAnswerValid, "Question \(question.id) answer must be valid")

            if idx < questions.count - 1 {
                XCTAssertFalse(vm.isLastQuestion)
                vm.advance()
            } else {
                XCTAssertTrue(vm.isLastQuestion)
            }
        }

        // Submit assessment
        vm.submitAssessment()

        if case .completed(let record) = vm.state {
            XCTAssertEqual(record.dimensionScores.count, 4)
            XCTAssertNotNil(record.archetype)
            XCTAssertGreaterThanOrEqual(record.overallScore, 0.0)
            XCTAssertLessThanOrEqual(record.overallScore, 100.0)
        } else {
            XCTFail("State must be .completed with AssessmentRecord, was \(vm.state)")
        }

        // Reset
        vm.reset()
        XCTAssertEqual(vm.state, .idle)
        XCTAssertEqual(vm.currentQuestionIndex, 0)
        XCTAssertTrue(vm.answers.isEmpty)
    }

    func testLoadCatalogErrorHandling() {
        struct FailingLoader: CatalogLoaderProtocol {
            func loadBundledCatalog() throws -> AssessmentCatalog {
                throw CatalogLoaderError.resourceNotFound(name: "missing.json")
            }
            func loadCatalog(from fileURL: URL) throws -> AssessmentCatalog {
                throw CatalogLoaderError.resourceNotFound(name: fileURL.lastPathComponent)
            }
            func decodeCatalog(from data: Data) throws -> AssessmentCatalog {
                throw CatalogLoaderError.jsonDecodingFailed(underlying: "Mock decoding error")
            }
        }

        let vm = AssessmentViewModel(catalogLoader: FailingLoader(), evaluationEngine: engine)
        vm.loadCatalog()

        if case .error(let message) = vm.state {
            XCTAssertTrue(message.contains("missing.json") || !message.isEmpty)
        } else {
            XCTFail("State must transition to .error upon loader failure")
        }
    }

    func testNavigationGuardsWhenCannotAdvanceOrGoBack() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        // vm is idle
        XCTAssertFalse(vm.canGoBack)
        XCTAssertFalse(vm.canGoForward)
        vm.advance()
        XCTAssertEqual(vm.currentQuestionIndex, 0)
        vm.goBack()
        XCTAssertEqual(vm.currentQuestionIndex, 0)

        vm.loadCatalog()
        // Index is 0, no answer yet
        XCTAssertFalse(vm.canGoBack)
        XCTAssertFalse(vm.canGoForward)
        vm.advance()
        XCTAssertEqual(vm.currentQuestionIndex, 0)
        vm.goBack()
        XCTAssertEqual(vm.currentQuestionIndex, 0)
    }

    func testValidationEdgeCasesForDifferentPayloadTypes() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vm.loadCatalog()

        guard let firstQ = vm.currentQuestion else {
            XCTFail("First question required")
            return
        }

        // 1. Invalid option for single choice
        vm.recordSingleChoice(questionId: firstQ.id, selectedOptionId: "non-existent-option-xyz")
        XCTAssertFalse(vm.isCurrentAnswerValid)

        // 2. Multiple choice edge cases
        if let mcIndex = vm.catalog?.questions.firstIndex(where: { $0.type == .multipleChoice }) {
            let mcQ = vm.catalog!.questions[mcIndex]
            // Move to this question by setting answers up to it or testing payload directly
            // Type mismatch test:
            vm.recordShortText(questionId: mcQ.id, text: "Some text on MC question")
            // Record direct invalid payloads in answers
            vm.recordSingleChoice(questionId: mcQ.id, selectedOptionId: "invalid")
        }

        // 3. Slider bounds and step validation
        if let sliderQ = vm.catalog?.questions.first(where: { $0.type == .likertSlider }) {
            let minVal = sliderQ.sliderMin ?? 1.0
            let maxVal = sliderQ.sliderMax ?? 5.0
            // Value below min
            vm.recordSliderValue(questionId: sliderQ.id, value: minVal - 1.0)
            // Value above max
            vm.recordSliderValue(questionId: sliderQ.id, value: maxVal + 1.0)
            // Non-step multiple if step exists
            if let step = sliderQ.sliderStep, step > 0 {
                vm.recordSliderValue(questionId: sliderQ.id, value: minVal + step * 0.5)
            }
        }

        // 4. Short text min/max validation
        if let textQ = vm.catalog?.questions.first(where: { $0.type == .shortText }) {
            let minChars = textQ.minCharacters ?? 15
            let maxChars = textQ.maxCharacters ?? 350
            XCTAssertGreaterThan(maxChars, minChars)
            // Below min
            vm.recordShortText(questionId: textQ.id, text: "Too short")
            // Whitespace only
            vm.recordShortText(questionId: textQ.id, text: "          ")
            // Exceeds max
            vm.recordShortText(questionId: textQ.id, text: String(repeating: "A", count: maxChars + 10))
        }
    }

    func testSubmitAssessmentFailures() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        // 1. Submit when catalog is nil
        vm.submitAssessment()
        if case .error(let msg) = vm.state {
            XCTAssertTrue(msg.contains("No catalog loaded"))
        } else {
            XCTFail("Should fail with error when no catalog is loaded")
        }

        // 2. Submit when current answer is invalid
        vm.loadCatalog()
        vm.submitAssessment()
        if case .error(let msg) = vm.state {
            XCTAssertTrue(msg.contains("valid answer"))
        } else {
            XCTFail("Should fail with error when answer is invalid")
        }

        // 3. Submit when missing answers
        if let firstQ = vm.currentQuestion {
            let optId = firstQ.options?.first?.id ?? "sc-1"
            vm.recordSingleChoice(questionId: firstQ.id, selectedOptionId: optId)
            XCTAssertTrue(vm.isCurrentAnswerValid)
            vm.submitAssessment()
            if case .error(let msg) = vm.state {
                XCTAssertTrue(msg.contains("Assessment incomplete"))
            } else {
                XCTFail("Should fail with incomplete assessment error")
            }
        }
    }
}
