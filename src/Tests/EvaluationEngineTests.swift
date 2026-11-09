import XCTest
@testable import AssessYourselfCore

final class EvaluationEngineTests: XCTestCase {
    var engine: AssessmentEvaluationEngine!
    var catalog: AssessmentCatalog!

    override func setUpWithError() throws {
        try super.setUpWithError()
        engine = AssessmentEvaluationEngine()
        let loader = LocalCatalogService()
        catalog = try loader.loadBundledCatalog()
    }

    override func tearDown() {
        engine = nil
        catalog = nil
        super.tearDown()
    }

    func testScoreSingleChoiceMatchesOptionWeight() {
        let question = catalog.questions.first(where: { $0.type == .singleChoice })!
        let bestOption = question.options!.first(where: { $0.scoreWeight == 100.0 })!

        let score = engine.scoreQuestion(
            question: question,
            selectedOptionIds: [bestOption.id],
            sliderValue: nil,
            textInput: nil
        )

        XCTAssertEqual(score, 100.0)
    }

    func testScoreSingleChoiceReturnsZeroWhenNoSelection() {
        let question = catalog.questions.first(where: { $0.type == .singleChoice })!

        let score = engine.scoreQuestion(
            question: question,
            selectedOptionIds: nil,
            sliderValue: nil,
            textInput: nil
        )

        XCTAssertEqual(score, 0.0)
    }

    func testScoreMultipleChoiceAggregatesWeights() {
        let question = catalog.questions.first(where: { $0.type == .multipleChoice })!
        let allOptionIds = question.options!.map(\.id)

        let score = engine.scoreQuestion(
            question: question,
            selectedOptionIds: allOptionIds,
            sliderValue: nil,
            textInput: nil
        )

        XCTAssertEqual(score, 100.0)
    }

    func testScoreLikertSliderNormalization() {
        let question = catalog.questions.first(where: { $0.type == .likertSlider })!

        // Value 1.0 on 1..5 scale should normalize to 0.0
        let minScore = engine.scoreQuestion(
            question: question,
            selectedOptionIds: nil,
            sliderValue: 1.0,
            textInput: nil
        )
        XCTAssertEqual(minScore, 0.0, accuracy: 0.001)

        // Value 5.0 on 1..5 scale should normalize to 100.0
        let maxScore = engine.scoreQuestion(
            question: question,
            selectedOptionIds: nil,
            sliderValue: 5.0,
            textInput: nil
        )
        XCTAssertEqual(maxScore, 100.0, accuracy: 0.001)

        // Value 3.0 on 1..5 scale should normalize to 50.0
        let midScore = engine.scoreQuestion(
            question: question,
            selectedOptionIds: nil,
            sliderValue: 3.0,
            textInput: nil
        )
        XCTAssertEqual(midScore, 50.0, accuracy: 0.001)
    }

    func testScoreShortTextAwardsKeywordsAndLength() {
        let question = catalog.questions.first(where: { $0.type == .shortText })!

        // Short below minimum (15 characters)
        let shortScore = engine.scoreQuestion(
            question: question,
            selectedOptionIds: nil,
            sliderValue: nil,
            textInput: "Kurz"
        )
        XCTAssertLessThanOrEqual(shortScore, 30.0)

        // Rich with exact technical keyword tokens
        let richText = "Wir verwenden ein sauberes ViewModel mit SwiftUI und XCTest, um Protokoll und Invarianten abzusichern."
        let richScore = engine.scoreQuestion(
            question: question,
            selectedOptionIds: nil,
            sliderValue: nil,
            textInput: richText
        )
        XCTAssertGreaterThanOrEqual(richScore, 90.0)
    }

    func testFullEvaluationSynthesizesArchetypeWithRealisticPayloads() throws {
        var answers: [AssessmentAnswer] = []

        for question in catalog.questions {
            var selectedIds: [String]?
            var sliderVal: Double?
            var text: String?

            switch question.type {
            case .singleChoice:
                let targetWeight: Double = (question.dimensionId == "architecture") ? 100.0 : 35.0
                if let option = question.options?.first(where: { $0.scoreWeight == targetWeight }) ?? question.options?.first {
                    selectedIds = [option.id]
                }
            case .multipleChoice:
                if question.dimensionId == "architecture" {
                    selectedIds = question.options?.map(\.id)
                } else {
                    selectedIds = question.options?.prefix(1).map(\.id)
                }
            case .likertSlider:
                sliderVal = (question.dimensionId == "architecture") ? 5.0 : 2.0
            case .shortText:
                if question.dimensionId == "architecture" {
                    text = "Wir verwenden saubere MVVM Schichten, Protocol Abstraktion und strikte Invarianten zur Entkopplung."
                } else {
                    text = "Eine einfache Standardbeschreibung ohne vertiefte Methodik."
                }
            }

            let answer = AssessmentAnswer(
                questionId: question.id,
                dimensionId: question.dimensionId,
                questionType: question.type,
                selectedOptionIds: selectedIds,
                sliderValue: sliderVal,
                textInput: text,
                normalizedScore: 0.0 // Engine will recompute derived score
            )
            answers.append(answer)
        }

        let record = try engine.evaluate(
            answers: answers,
            catalog: catalog,
            durationSeconds: 120.0
        )

        XCTAssertEqual(record.catalogId, catalog.catalogId)
        XCTAssertGreaterThan(record.dimensionScores["architecture"]!, record.dimensionScores["platform"]!)
        XCTAssertEqual(record.archetype.id, "system-architect")
    }

    func testEvaluationRejectsDuplicateAnswers() {
        let q = catalog.questions[0]
        let optId = q.options![0].id
        let a1 = AssessmentAnswer(questionId: q.id, dimensionId: q.dimensionId, questionType: q.type, selectedOptionIds: [optId], normalizedScore: 100.0)
        let a2 = AssessmentAnswer(questionId: q.id, dimensionId: q.dimensionId, questionType: q.type, selectedOptionIds: [optId], normalizedScore: 50.0)

        XCTAssertThrowsError(try engine.evaluate(answers: [a1, a2], catalog: catalog, durationSeconds: 10.0)) { error in
            guard case EvaluationEngineError.duplicateAnswer(let qid) = error else {
                XCTFail("Expected duplicateAnswer error, got: \(error)")
                return
            }
            XCTAssertEqual(qid, q.id)
        }
    }

    func testEvaluationRejectsUnknownQuestionId() {
        let fake = AssessmentAnswer(
            questionId: "unknown-question-id",
            dimensionId: "architecture",
            questionType: .singleChoice,
            selectedOptionIds: ["any"],
            normalizedScore: 100.0
        )

        XCTAssertThrowsError(try engine.evaluate(answers: [fake], catalog: catalog, durationSeconds: 10.0)) { error in
            guard case EvaluationEngineError.unknownQuestion(let qid) = error else {
                XCTFail("Expected unknownQuestion error, got: \(error)")
                return
            }
            XCTAssertEqual(qid, "unknown-question-id")
        }
    }

    func testEvaluationRejectsMismatchedDimension() {
        let q = catalog.questions.first(where: { $0.dimensionId == "architecture" })!
        let optId = q.options![0].id
        let forged = AssessmentAnswer(
            questionId: q.id,
            dimensionId: "quality", // Mismatched
            questionType: q.type,
            selectedOptionIds: [optId],
            normalizedScore: 100.0
        )

        XCTAssertThrowsError(try engine.evaluate(answers: [forged], catalog: catalog, durationSeconds: 10.0)) { error in
            guard case EvaluationEngineError.mismatchedDimension(let qid, let exp, let act) = error else {
                XCTFail("Expected mismatchedDimension error, got: \(error)")
                return
            }
            XCTAssertEqual(qid, q.id)
            XCTAssertEqual(exp, "architecture")
            XCTAssertEqual(act, "quality")
        }
    }

    func testArchetypeTieBreakingIs100PercentDeterministic() {
        // When all dimensions score zero, ensure 50 repeated executions return the exact same archetype
        let zeroScores: [String: Double] = [
            "architecture": 0.0,
            "platform": 0.0,
            "quality": 0.0,
            "agile": 0.0
        ]

        let firstArchetype = engine.selectDominantArchetype(
            dimensionScores: zeroScores,
            dimensions: catalog.dimensions,
            archetypes: catalog.archetypes
        )

        // In catalog.dimensions, the first declared dimension is "architecture" -> "system-architect"
        XCTAssertEqual(firstArchetype.id, "system-architect")

        for _ in 1...50 {
            let repeated = engine.selectDominantArchetype(
                dimensionScores: zeroScores,
                dimensions: catalog.dimensions,
                archetypes: catalog.archetypes
            )
            XCTAssertEqual(repeated.id, firstArchetype.id, "Tie-breaker must be 100% deterministic across iterations")
        }
    }

    func testStrictTransitivityOfRecordComparison() {
        // Verify strict transitivity cycle test with micro-variations in scores and timestamps
        let baseDate = Date()
        let recA = AssessmentRecord(
            catalogId: "cat",
            completedAt: baseDate.addingTimeInterval(30),
            durationSeconds: 100.0,
            dimensionScores: [:],
            overallScore: 50.0,
            archetype: ArchetypeProfile.standardArchetypes[0],
            answers: []
        )
        let recB = AssessmentRecord(
            catalogId: "cat",
            completedAt: baseDate.addingTimeInterval(20),
            durationSeconds: 100.0,
            dimensionScores: [:],
            overallScore: 50.00075,
            archetype: ArchetypeProfile.standardArchetypes[0],
            answers: []
        )
        let recC = AssessmentRecord(
            catalogId: "cat",
            completedAt: baseDate.addingTimeInterval(10),
            durationSeconds: 100.0,
            dimensionScores: [:],
            overallScore: 50.0015,
            archetype: ArchetypeProfile.standardArchetypes[0],
            answers: []
        )

        // Strict ordering: recA (50.0) < recB (50.00075) < recC (50.0015)
        XCTAssertTrue(recA < recB)
        XCTAssertTrue(recB < recC)
        XCTAssertTrue(recA < recC, "Transitivity must hold: if A < B and B < C, then A < C")
        XCTAssertFalse(recC < recA, "Antisymmetry must hold: if A < C, then not C < A")
    }

    func testDecoderClampsForgedNormalizedScoreJSON() throws {
        let json = Data("""
        {
            "questionId": "arch-sc-01",
            "dimensionId": "architecture",
            "questionType": "single_choice",
            "normalizedScore": 999.0
        }
        """.utf8)

        let answer = try JSONDecoder().decode(AssessmentAnswer.self, from: json)
        XCTAssertEqual(answer.normalizedScore, 100.0, "Decoder must strictly clamp normalizedScore to 100.0")
    }

    // MARK: - Incomplete Assessment & Payload Validation Tests

    private func makeCompleteAnswers() -> [AssessmentAnswer] {
        var answers: [AssessmentAnswer] = []
        for question in catalog.questions {
            var selectedIds: [String]?
            var sliderVal: Double?
            var text: String?

            switch question.type {
            case .singleChoice:
                selectedIds = [question.options!.first!.id]
            case .multipleChoice:
                selectedIds = [question.options!.first!.id]
            case .likertSlider:
                sliderVal = 3.0
            case .shortText:
                text = "Saubere Architektur mit MVVM, Protocol Abstraktion und strikten Tests."
            }

            answers.append(AssessmentAnswer(
                questionId: question.id,
                dimensionId: question.dimensionId,
                questionType: question.type,
                selectedOptionIds: selectedIds,
                sliderValue: sliderVal,
                textInput: text
            ))
        }
        return answers
    }

    func testEvaluationRejectsIncompleteAssessment() {
        var answers = makeCompleteAnswers()
        answers.removeLast() // Now missing 1 question

        XCTAssertThrowsError(try engine.evaluate(answers: answers, catalog: catalog, durationSeconds: 60.0)) { error in
            guard case EvaluationEngineError.incompleteAssessment(let missing) = error else {
                XCTFail("Expected incompleteAssessment error, got: \(error)")
                return
            }
            XCTAssertEqual(missing.count, 1)
        }
    }

    func testEvaluationRejectsCatalogIntegrityViolation() {
        let q1 = AssessmentQuestion(id: "dup", dimensionId: "architecture", type: .likertSlider, title: "Q", prompt: "P")
        let q2 = AssessmentQuestion(id: "dup", dimensionId: "architecture", type: .likertSlider, title: "Q", prompt: "P")
        let brokenCatalog = AssessmentCatalog(
            catalogId: "bad",
            version: "1.0",
            title: "T",
            subtitle: "S",
            description: "D",
            dimensions: AssessmentDimension.standardDimensions,
            questions: [q1, q2],
            archetypes: ArchetypeProfile.standardArchetypes
        )

        let answer = AssessmentAnswer(questionId: "dup", dimensionId: "architecture", questionType: .likertSlider, sliderValue: 3.0)

        XCTAssertThrowsError(try engine.evaluate(answers: [answer], catalog: brokenCatalog, durationSeconds: 10.0)) { error in
            guard case EvaluationEngineError.catalogIntegrityViolation = error else {
                XCTFail("Expected catalogIntegrityViolation error, got: \(error)")
                return
            }
        }
    }

    func testEvaluationRejectsInvalidSingleChoicePayload() {
        var answers = makeCompleteAnswers()
        // Replace single choice answer with an unknown option ID
        if let idx = answers.firstIndex(where: { $0.questionType == .singleChoice }) {
            let original = answers[idx]
            answers[idx] = AssessmentAnswer(
                questionId: original.questionId,
                dimensionId: original.dimensionId,
                questionType: original.questionType,
                selectedOptionIds: ["non-existent-option-id"]
            )

            XCTAssertThrowsError(try engine.evaluate(answers: answers, catalog: catalog, durationSeconds: 60.0)) { error in
                guard case EvaluationEngineError.invalidPayload(let qid, _) = error else {
                    XCTFail("Expected invalidPayload error, got: \(error)")
                    return
                }
                XCTAssertEqual(qid, original.questionId)
            }
        }
    }

    func testSingleChoiceRejectsMultipleSelections() {
        var answers = makeCompleteAnswers()
        if let idx = answers.firstIndex(where: { $0.questionType == .singleChoice }) {
            let original = answers[idx]
            let q = catalog.questions.first(where: { $0.id == original.questionId })!
            let opt1 = q.options![0].id
            let opt2 = q.options![1].id

            // Attempting to select 2 options on a Single Choice question
            answers[idx] = AssessmentAnswer(
                questionId: original.questionId,
                dimensionId: original.dimensionId,
                questionType: original.questionType,
                selectedOptionIds: [opt1, opt2]
            )

            XCTAssertThrowsError(try engine.evaluate(answers: answers, catalog: catalog, durationSeconds: 60.0)) { error in
                guard case EvaluationEngineError.invalidPayload(let qid, let reason) = error else {
                    XCTFail("Expected invalidPayload error, got: \(error)")
                    return
                }
                XCTAssertEqual(qid, original.questionId)
                XCTAssertTrue(reason.contains("Single choice requires exactly one"))
            }
        }
    }

    func testEvaluationRejectsInvalidMultipleChoicePayload() {
        var answers = makeCompleteAnswers()
        if let idx = answers.firstIndex(where: { $0.questionType == .multipleChoice }) {
            let original = answers[idx]
            // Empty selection for multiple choice
            answers[idx] = AssessmentAnswer(
                questionId: original.questionId,
                dimensionId: original.dimensionId,
                questionType: original.questionType,
                selectedOptionIds: []
            )

            XCTAssertThrowsError(try engine.evaluate(answers: answers, catalog: catalog, durationSeconds: 60.0)) { error in
                guard case EvaluationEngineError.invalidPayload(let qid, _) = error else {
                    XCTFail("Expected invalidPayload error, got: \(error)")
                    return
                }
                XCTAssertEqual(qid, original.questionId)
            }
        }
    }

    func testMultipleChoiceRejectsDuplicateSelectedOptionIds() {
        var answers = makeCompleteAnswers()
        if let idx = answers.firstIndex(where: { $0.questionType == .multipleChoice }) {
            let original = answers[idx]
            let q = catalog.questions.first(where: { $0.id == original.questionId })!
            let opt1 = q.options![0].id

            // Attempting to submit duplicate selections: [opt1, opt1]
            answers[idx] = AssessmentAnswer(
                questionId: original.questionId,
                dimensionId: original.dimensionId,
                questionType: original.questionType,
                selectedOptionIds: [opt1, opt1]
            )

            XCTAssertThrowsError(try engine.evaluate(answers: answers, catalog: catalog, durationSeconds: 60.0)) { error in
                guard case EvaluationEngineError.invalidPayload(let qid, let reason) = error else {
                    XCTFail("Expected invalidPayload error, got: \(error)")
                    return
                }
                XCTAssertEqual(qid, original.questionId)
                XCTAssertTrue(reason.contains("duplicate selected option"))
            }
        }
    }

    func testEvaluationRejectsInvalidSliderPayload() {
        var answers = makeCompleteAnswers()
        if let idx = answers.firstIndex(where: { $0.questionType == .likertSlider }) {
            let original = answers[idx]
            // Slider value out of bounds
            answers[idx] = AssessmentAnswer(
                questionId: original.questionId,
                dimensionId: original.dimensionId,
                questionType: original.questionType,
                sliderValue: 99.0
            )

            XCTAssertThrowsError(try engine.evaluate(answers: answers, catalog: catalog, durationSeconds: 60.0)) { error in
                guard case EvaluationEngineError.invalidPayload(let qid, _) = error else {
                    XCTFail("Expected invalidPayload error, got: \(error)")
                    return
                }
                XCTAssertEqual(qid, original.questionId)
            }
        }
    }

    func testSliderRejectsValueViolatingStep() {
        var answers = makeCompleteAnswers()
        if let idx = answers.firstIndex(where: { $0.questionType == .likertSlider }) {
            let original = answers[idx]
            // Step is 1.0 (range 1.0 to 5.0). Passing 2.5 must violate step constraint.
            answers[idx] = AssessmentAnswer(
                questionId: original.questionId,
                dimensionId: original.dimensionId,
                questionType: original.questionType,
                sliderValue: 2.5
            )

            XCTAssertThrowsError(try engine.evaluate(answers: answers, catalog: catalog, durationSeconds: 60.0)) { error in
                guard case EvaluationEngineError.invalidPayload(let qid, let reason) = error else {
                    XCTFail("Expected invalidPayload error, got: \(error)")
                    return
                }
                XCTAssertEqual(qid, original.questionId)
                XCTAssertTrue(reason.contains("does not conform to configured step"))
            }
        }
    }

    func testEvaluationRejectsInvalidShortTextPayload() {
        var answers = makeCompleteAnswers()
        if let idx = answers.firstIndex(where: { $0.questionType == .shortText }) {
            let original = answers[idx]
            // Text too short (< 15 chars)
            answers[idx] = AssessmentAnswer(
                questionId: original.questionId,
                dimensionId: original.dimensionId,
                questionType: original.questionType,
                textInput: "Zu kurz"
            )

            XCTAssertThrowsError(try engine.evaluate(answers: answers, catalog: catalog, durationSeconds: 60.0)) { error in
                guard case EvaluationEngineError.invalidPayload(let qid, _) = error else {
                    XCTFail("Expected invalidPayload error, got: \(error)")
                    return
                }
                XCTAssertEqual(qid, original.questionId)
            }
        }
    }

    func testEvaluationEngineErrorDescriptions() {
        let errors: [EvaluationEngineError] = [
            .emptyAnswers,
            .duplicateAnswer(questionId: "q1"),
            .unknownQuestion(questionId: "q2"),
            .mismatchedDimension(questionId: "q3", expected: "arch", actual: "qual"),
            .mismatchedType(questionId: "q4", expected: .singleChoice, actual: .likertSlider),
            .incompleteAssessment(missingQuestionIds: ["q5"]),
            .invalidPayload(questionId: "q6", reason: "bad"),
            .catalogIntegrityViolation(reason: "broken")
        ]

        for err in errors {
            XCTAssertFalse(err.errorDescription!.isEmpty)
        }
    }
}
