import XCTest
@testable import AssessYourselfCore

final class CatalogTests: XCTestCase {
    var loader: LocalCatalogService!

    override func setUp() {
        super.setUp()
        loader = LocalCatalogService()
    }

    override func tearDown() {
        loader = nil
        super.tearDown()
    }

    func testLoadBundledCatalogSucceeds() throws {
        let catalog = try loader.loadBundledCatalog()

        XCTAssertEqual(catalog.catalogId, "devprofile-se-2026")
        XCTAssertEqual(catalog.version, "1.0.0")
        XCTAssertEqual(catalog.dimensions.count, 4)
        XCTAssertEqual(catalog.questions.count, 24)
        XCTAssertEqual(catalog.archetypes.count, 4)
    }

    func testCatalogDimensionsCoverage() throws {
        let catalog = try loader.loadBundledCatalog()
        let dimensionIds = Set(catalog.dimensions.map(\.id))

        XCTAssertTrue(dimensionIds.contains("architecture"))
        XCTAssertTrue(dimensionIds.contains("platform"))
        XCTAssertTrue(dimensionIds.contains("quality"))
        XCTAssertTrue(dimensionIds.contains("agile"))

        // Each dimension should have exactly 6 questions
        for dimId in dimensionIds {
            let count = catalog.questions.filter { $0.dimensionId == dimId }.count
            XCTAssertEqual(count, 6, "Dimension \(dimId) should have exactly 6 questions")
        }
    }

    func testQuestionTypesAreAllRepresented() throws {
        let catalog = try loader.loadBundledCatalog()
        let types = Set(catalog.questions.map(\.type))

        XCTAssertTrue(types.contains(.singleChoice))
        XCTAssertTrue(types.contains(.multipleChoice))
        XCTAssertTrue(types.contains(.likertSlider))
        XCTAssertTrue(types.contains(.shortText))
    }

    func testQuestionInvariantValidationThrowsOnEmptyPrompt() {
        let question = AssessmentQuestion(
            id: "test-01",
            dimensionId: "architecture",
            type: .likertSlider,
            title: "Test",
            prompt: "   "
        )
        XCTAssertThrowsError(try question.validateInvariants()) { error in
            guard case AssessmentValidationError.emptyPrompt(let qid) = error else {
                XCTFail("Expected emptyPrompt error, got: \(error)")
                return
            }
            XCTAssertEqual(qid, "test-01")
        }
    }

    func testChoiceQuestionThrowsOnInsufficientOptions() {
        let question = AssessmentQuestion(
            id: "choice-bad",
            dimensionId: "platform",
            type: .singleChoice,
            title: "Choice Test",
            prompt: "Choose",
            options: [
                ChoiceOption(id: "opt-1", title: "Single", scoreWeight: 100.0)
            ]
        )
        XCTAssertThrowsError(try question.validateInvariants()) { error in
            guard case AssessmentValidationError.insufficientOptions = error else {
                XCTFail("Expected insufficientOptions error, got: \(error)")
                return
            }
        }
    }

    func testSliderQuestionThrowsOnInvertedRange() {
        let question = AssessmentQuestion(
            id: "slider-bad",
            dimensionId: "quality",
            type: .likertSlider,
            title: "Slider Test",
            prompt: "Slide",
            sliderMin: 5.0,
            sliderMax: 1.0
        )
        XCTAssertThrowsError(try question.validateInvariants()) { error in
            guard case AssessmentValidationError.invalidSliderRange = error else {
                XCTFail("Expected invalidSliderRange error, got: \(error)")
                return
            }
        }
    }

    func testSliderQuestionThrowsOnNonPositiveStep() {
        let question = AssessmentQuestion(
            id: "slider-step-zero",
            dimensionId: "quality",
            type: .likertSlider,
            title: "Slider Step Test",
            prompt: "Slide",
            sliderMin: 1.0,
            sliderMax: 5.0,
            sliderStep: 0.0
        )
        XCTAssertThrowsError(try question.validateInvariants()) { error in
            guard case AssessmentValidationError.invalidSliderStep = error else {
                XCTFail("Expected invalidSliderStep error, got: \(error)")
                return
            }
        }
    }

    func testSliderQuestionThrowsOnDefaultOutsideRange() {
        let question = AssessmentQuestion(
            id: "slider-def-bad",
            dimensionId: "quality",
            type: .likertSlider,
            title: "Slider Default Test",
            prompt: "Slide",
            sliderMin: 1.0,
            sliderMax: 5.0,
            sliderDefault: 99.0
        )
        XCTAssertThrowsError(try question.validateInvariants()) { error in
            guard case AssessmentValidationError.invalidSliderDefault = error else {
                XCTFail("Expected invalidSliderDefault error, got: \(error)")
                return
            }
        }
    }

    func testMultiSelectThrowsOnInvalidBounds() {
        let question = AssessmentQuestion(
            id: "multi-bad-bounds",
            dimensionId: "agile",
            type: .multipleChoice,
            title: "Multi Test",
            prompt: "Select",
            options: [
                ChoiceOption(id: "opt-1", title: "A", scoreWeight: 50.0),
                ChoiceOption(id: "opt-2", title: "B", scoreWeight: 50.0)
            ],
            minSelectCount: 5,
            maxSelectCount: 1
        )
        XCTAssertThrowsError(try question.validateInvariants()) { error in
            guard case AssessmentValidationError.invalidMultiSelectBounds = error else {
                XCTFail("Expected invalidMultiSelectBounds error, got: \(error)")
                return
            }
        }
    }

    func testCatalogRejectsDuplicateQuestionIds() {
        let q1 = AssessmentQuestion(id: "dup-id", dimensionId: "architecture", type: .likertSlider, title: "Q1", prompt: "Prompt 1")
        let q2 = AssessmentQuestion(id: "dup-id", dimensionId: "architecture", type: .likertSlider, title: "Q2", prompt: "Prompt 2")

        let badCatalog = AssessmentCatalog(
            catalogId: "bad-cat",
            version: "1.0.0",
            title: "Bad",
            subtitle: "Sub",
            description: "Desc",
            dimensions: AssessmentDimension.standardDimensions,
            questions: [q1, q2],
            archetypes: ArchetypeProfile.standardArchetypes
        )

        XCTAssertThrowsError(try badCatalog.validateIntegrity()) { error in
            guard case AssessmentCatalogError.duplicateQuestionId(let qid) = error else {
                XCTFail("Expected duplicateQuestionId error, got: \(error)")
                return
            }
            XCTAssertEqual(qid, "dup-id")
        }
    }

    func testCatalogRejectsArchetypeWithUnmappedDimension() {
        let q = AssessmentQuestion(id: "q-1", dimensionId: "architecture", type: .likertSlider, title: "Q1", prompt: "Prompt 1")
        let badArchetype = ArchetypeProfile(
            id: "bad-arc",
            title: "Bad Archetype",
            subtitle: "Sub",
            dominantDimensionId: "non-existent-dim",
            description: "Desc",
            strengths: [],
            growthOpportunities: [],
            badgeSymbol: "star"
        )

        let badCatalog = AssessmentCatalog(
            catalogId: "bad-cat-arc",
            version: "1.0.0",
            title: "Bad",
            subtitle: "Sub",
            description: "Desc",
            dimensions: AssessmentDimension.standardDimensions,
            questions: [q],
            archetypes: [badArchetype]
        )

        XCTAssertThrowsError(try badCatalog.validateIntegrity()) { error in
            guard case AssessmentCatalogError.unmappedArchetypeDimension(let aid, let dim) = error else {
                XCTFail("Expected unmappedArchetypeDimension error, got: \(error)")
                return
            }
            XCTAssertEqual(aid, "bad-arc")
            XCTAssertEqual(dim, "non-existent-dim")
        }
    }
}
