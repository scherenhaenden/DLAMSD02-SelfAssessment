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

        // Short below minimum
        let shortScore = engine.scoreQuestion(
            question: question,
            selectedOptionIds: nil,
            sliderValue: nil,
            textInput: "Kurz"
        )
        XCTAssertLessThan(shortScore, 40.0)

        // Rich with technical keywords
        let richText = "Wir verwenden ein sauberes ViewModel mit SwiftUI und XCTest, um Protokoll und Invarianten abzusichern."
        let richScore = engine.scoreQuestion(
            question: question,
            selectedOptionIds: nil,
            sliderValue: nil,
            textInput: richText
        )
        XCTAssertGreaterThanOrEqual(richScore, 90.0)
    }

    func testFullEvaluationSynthesizesArchetype() throws {
        // Generate answers where architecture questions score 100% and others 50%
        var answers: [AssessmentAnswer] = []

        for question in catalog.questions {
            let score: Double = (question.dimensionId == "architecture") ? 100.0 : 50.0
            let answer = AssessmentAnswer(
                questionId: question.id,
                dimensionId: question.dimensionId,
                questionType: question.type,
                selectedOptionIds: nil,
                sliderValue: nil,
                textInput: nil,
                normalizedScore: score
            )
            answers.append(answer)
        }

        let record = try engine.evaluate(
            answers: answers,
            catalog: catalog,
            durationSeconds: 120.0
        )

        XCTAssertEqual(record.catalogId, catalog.catalogId)
        XCTAssertEqual(record.dimensionScores["architecture"], 100.0)
        XCTAssertEqual(record.dimensionScores["platform"], 50.0)
        XCTAssertEqual(record.archetype.id, "system-architect")
        XCTAssertEqual(record.overallScore, (100.0 + 50.0 * 3) / 4.0, accuracy: 0.001)
    }
}
