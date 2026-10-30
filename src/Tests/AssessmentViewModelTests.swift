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

    private func advanceToQuestion(vm: AssessmentViewModel, targetType: QuestionType) {
        var guardCounter = 0
        while let current = vm.currentQuestion, current.type != targetType && guardCounter < 30 {
            guardCounter += 1
            switch current.type {
            case .singleChoice:
                let optId = current.options?.first?.id ?? "sc"
                vm.recordSingleChoice(questionId: current.id, selectedOptionId: optId)
            case .multipleChoice:
                let optId = current.options?.first?.id ?? "mc"
                vm.toggleMultipleChoice(questionId: current.id, optionId: optId)
            case .likertSlider:
                vm.recordSliderValue(questionId: current.id, value: current.sliderDefault ?? 3.0)
            case .shortText:
                vm.recordShortText(questionId: current.id, text: "Gültiger Testtext mit mehr als 25 Zeichen.")
            }
            let prev = vm.currentQuestionIndex
            vm.advance()
            if vm.currentQuestionIndex == prev {
                break
            }
        }
    }

    func testInitialStateAndLoadCatalogSuccess() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        XCTAssertEqual(vm.state, .idle)
        XCTAssertNil(vm.catalog)
        XCTAssertEqual(vm.currentQuestionIndex, 0)
        XCTAssertEqual(vm.totalQuestions, 0)
        XCTAssertNil(vm.currentQuestion)
        XCTAssertNil(vm.currentDimension)
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

        // Initially no answer recorded for single choice
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

        // Advance to multiple choice question
        advanceToQuestion(vm: vm, targetType: .multipleChoice)
        guard let mcQuestion = vm.currentQuestion, mcQuestion.type == .multipleChoice,
              let options = mcQuestion.options, options.count >= 4 else {
            XCTFail("Must be at multiple choice question with >= 4 options")
            return
        }

        let qId = mcQuestion.id
        let minCount = mcQuestion.minSelectCount ?? 1
        let maxCount = mcQuestion.maxSelectCount ?? 3
        XCTAssertGreaterThanOrEqual(maxCount, minCount)

        // Initially no selection on this question
        XCTAssertFalse(vm.isCurrentAnswerValid)
        XCTAssertFalse(vm.canGoForward)

        // Toggle 1st option -> within bounds [1...3] -> valid
        vm.toggleMultipleChoice(questionId: qId, optionId: options[0].id)
        XCTAssertTrue(vm.isCurrentAnswerValid)
        XCTAssertTrue(vm.canGoForward)
        if case .multipleChoice(let ids) = vm.answers[qId] {
            XCTAssertEqual(ids, [options[0].id])
        }

        // Toggle 2nd option -> within bounds -> valid
        vm.toggleMultipleChoice(questionId: qId, optionId: options[1].id)
        XCTAssertTrue(vm.isCurrentAnswerValid)
        if case .multipleChoice(let ids) = vm.answers[qId] {
            XCTAssertEqual(ids.count, 2)
        }

        // Toggle 3rd option -> reached maxSelectCount (3) -> valid
        vm.toggleMultipleChoice(questionId: qId, optionId: options[2].id)
        XCTAssertTrue(vm.isCurrentAnswerValid)
        if case .multipleChoice(let ids) = vm.answers[qId] {
            XCTAssertEqual(ids.count, 3)
        }

        // Toggle 4th option -> reached maxSelectCount (4) -> valid
        vm.toggleMultipleChoice(questionId: qId, optionId: options[3].id)
        XCTAssertTrue(vm.isCurrentAnswerValid)
        if case .multipleChoice(let ids) = vm.answers[qId] {
            XCTAssertEqual(ids.count, 4)
        }

        // Attempt to toggle a 5th option -> blocked by maxSelectCount guard -> count remains 4
        vm.toggleMultipleChoice(questionId: qId, optionId: "extra-option-5")
        if case .multipleChoice(let ids) = vm.answers[qId] {
            XCTAssertEqual(ids.count, 4)
        }

        // Deselect all options
        vm.toggleMultipleChoice(questionId: qId, optionId: options[0].id)
        vm.toggleMultipleChoice(questionId: qId, optionId: options[1].id)
        vm.toggleMultipleChoice(questionId: qId, optionId: options[2].id)
        vm.toggleMultipleChoice(questionId: qId, optionId: options[3].id)

        // All deselected -> dictionary entry removed -> invalid
        XCTAssertNil(vm.answers[qId])
        XCTAssertFalse(vm.isCurrentAnswerValid)
    }

    func testSliderAnswerRecordingAndValidation() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vm.loadCatalog()

        advanceToQuestion(vm: vm, targetType: .likertSlider)
        guard let sliderQuestion = vm.currentQuestion, sliderQuestion.type == .likertSlider else {
            XCTFail("Must be at stepped slider question")
            return
        }

        let qId = sliderQuestion.id
        let minVal = sliderQuestion.sliderMin ?? 1.0
        let maxVal = sliderQuestion.sliderMax ?? 5.0
        let step = sliderQuestion.sliderStep ?? 1.0

        // Stepped slider automatically registers default value upon navigating
        XCTAssertTrue(vm.isCurrentAnswerValid)
        XCTAssertEqual(vm.answers[qId], .steppedSlider(value: sliderQuestion.sliderDefault ?? 3.0))

        // Below min -> invalid
        vm.recordSliderValue(questionId: qId, value: minVal - 1.0)
        XCTAssertFalse(vm.isCurrentAnswerValid)

        // Above max -> invalid
        vm.recordSliderValue(questionId: qId, value: maxVal + 1.0)
        XCTAssertFalse(vm.isCurrentAnswerValid)

        // Step violation -> invalid
        if step > 0 {
            vm.recordSliderValue(questionId: qId, value: minVal + step * 0.5)
            XCTAssertFalse(vm.isCurrentAnswerValid)
        }

        // Compliant value -> valid
        let validVal = minVal + step
        vm.recordSliderValue(questionId: qId, value: validVal)
        XCTAssertTrue(vm.isCurrentAnswerValid)
        XCTAssertTrue(vm.canGoForward)

        if case .steppedSlider(let val) = vm.answers[qId] {
            XCTAssertEqual(val, validVal)
        } else {
            XCTFail("Recorded answer must match steppedSlider payload")
        }
    }

    func testShortTextAnswerRecordingAndValidation() {
        let vm = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vm.loadCatalog()

        advanceToQuestion(vm: vm, targetType: .shortText)
        guard let textQuestion = vm.currentQuestion, textQuestion.type == .shortText else {
            XCTFail("Must be at short text question")
            return
        }

        let qId = textQuestion.id
        let minChars = textQuestion.minCharacters ?? 15
        let maxChars = textQuestion.maxCharacters ?? 350

        // Initially no answer
        XCTAssertFalse(vm.isCurrentAnswerValid)

        // Empty text
        vm.recordShortText(questionId: qId, text: "")
        XCTAssertFalse(vm.isCurrentAnswerValid)

        // Whitespace only
        vm.recordShortText(questionId: qId, text: "          ")
        XCTAssertFalse(vm.isCurrentAnswerValid)

        // Too short (< minChars)
        vm.recordShortText(questionId: qId, text: "Zu kurz")
        XCTAssertFalse(vm.isCurrentAnswerValid)

        // Exceeds max (> maxChars)
        let tooLongText = String(repeating: "A", count: maxChars + 10)
        vm.recordShortText(questionId: qId, text: tooLongText)
        XCTAssertFalse(vm.isCurrentAnswerValid)

        // Valid text
        let validText = "Praxiseinsatz mit sauberer Architektur und TDD."
        XCTAssertGreaterThan(validText.count, minChars)
        XCTAssertLessThanOrEqual(validText.count, maxChars)

        vm.recordShortText(questionId: qId, text: validText)
        XCTAssertTrue(vm.isCurrentAnswerValid)
        XCTAssertTrue(vm.canGoForward)

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
        // 1. Single choice invalid option & type mismatches
        let vmSC = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vmSC.loadCatalog()
        if let firstQ = vmSC.currentQuestion {
            vmSC.recordSingleChoice(questionId: firstQ.id, selectedOptionId: "non-existent-option-xyz")
            XCTAssertFalse(vmSC.isCurrentAnswerValid)

            vmSC.recordShortText(questionId: firstQ.id, text: "Some text on SC question")
            XCTAssertFalse(vmSC.isCurrentAnswerValid)

            vmSC.recordSliderValue(questionId: firstQ.id, value: 3.0)
            XCTAssertFalse(vmSC.isCurrentAnswerValid)
        }

        // 2. Multiple choice edge cases
        let vmMC = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vmMC.loadCatalog()
        advanceToQuestion(vm: vmMC, targetType: .multipleChoice)
        if let mcQ = vmMC.currentQuestion {
            // Type mismatch
            vmMC.recordShortText(questionId: mcQ.id, text: "Short text payload")
            XCTAssertFalse(vmMC.isCurrentAnswerValid)

            vmMC.recordSliderValue(questionId: mcQ.id, value: 3.0)
            XCTAssertFalse(vmMC.isCurrentAnswerValid)

            // Unknown option ID
            vmMC.toggleMultipleChoice(questionId: mcQ.id, optionId: "unknown-option-id-404")
            XCTAssertFalse(vmMC.isCurrentAnswerValid)
        }

        // 3. Short text edge cases
        let vmTX = AssessmentViewModel(catalogLoader: loader, evaluationEngine: engine)
        vmTX.loadCatalog()
        advanceToQuestion(vm: vmTX, targetType: .shortText)
        if let textQ = vmTX.currentQuestion {
            vmTX.recordSliderValue(questionId: textQ.id, value: 3.0)
            XCTAssertFalse(vmTX.isCurrentAnswerValid)

            vmTX.recordSingleChoice(questionId: textQ.id, selectedOptionId: "opt")
            XCTAssertFalse(vmTX.isCurrentAnswerValid)
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

        // 4. Submit when Evaluation Engine throws error
        struct ThrowingEngine: EvaluationEngineProtocol {
            func evaluate(answers: [AssessmentAnswer], catalog: AssessmentCatalog, durationSeconds: Double) throws -> AssessmentRecord {
                throw EvaluationEngineError.emptyAnswers
            }
            func scoreQuestion(question: AssessmentQuestion, selectedOptionIds: [String]?, sliderValue: Double?, textInput: String?) -> Double {
                0.0
            }
        }

        let throwingVM = AssessmentViewModel(catalogLoader: loader, evaluationEngine: ThrowingEngine())
        throwingVM.loadCatalog()
        if let questions = throwingVM.catalog?.questions {
            for q in questions {
                switch q.type {
                case .singleChoice:
                    let optId = q.options?.first?.id ?? "sc"
                    throwingVM.recordSingleChoice(questionId: q.id, selectedOptionId: optId)
                case .multipleChoice:
                    let optId = q.options?.first?.id ?? "mc"
                    throwingVM.toggleMultipleChoice(questionId: q.id, optionId: optId)
                case .likertSlider:
                    throwingVM.recordSliderValue(questionId: q.id, value: 3.0)
                case .shortText:
                    throwingVM.recordShortText(questionId: q.id, text: "Gültiger Testtext mit ausreichender Länge.")
                }
            }
            throwingVM.submitAssessment()
            if case .error(let msg) = throwingVM.state {
                XCTAssertTrue(msg.contains("empty") || !msg.isEmpty)
            } else {
                XCTFail("Must transition to .error when evaluation engine throws")
            }
        }
    }
}
