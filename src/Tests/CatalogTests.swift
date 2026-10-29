import XCTest
@testable import AssessYourselfCore

final class CatalogTests: XCTestCase {
    var loader: LocalCatalogService!

    override func setUp() {
        super.setUp()
        loader = LocalCatalogService(bundle: .module)
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
}
