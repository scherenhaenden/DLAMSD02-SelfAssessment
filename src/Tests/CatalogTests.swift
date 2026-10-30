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

    // MARK: - Exhaustive Catalog & Question Invariant Error Tests

    func testCatalogRejectsMissingCatalogIdAndEmptyEntities() {
        let validQ = AssessmentQuestion(id: "q-1", dimensionId: "architecture", type: .likertSlider, title: "Q1", prompt: "P1")

        // 1. Missing Catalog ID
        let emptyIdCat = AssessmentCatalog(catalogId: "  ", version: "1.0", title: "T", subtitle: "S", description: "D", dimensions: AssessmentDimension.standardDimensions, questions: [validQ], archetypes: ArchetypeProfile.standardArchetypes)
        XCTAssertThrowsError(try emptyIdCat.validateIntegrity()) {
            XCTAssertEqual($0 as? AssessmentCatalogError, .missingCatalogId)
            XCTAssertNotNil(($0 as? AssessmentCatalogError)?.errorDescription)
        }

        // 2. Empty Dimensions
        let emptyDimsCat = AssessmentCatalog(catalogId: "c1", version: "1.0", title: "T", subtitle: "S", description: "D", dimensions: [], questions: [validQ], archetypes: ArchetypeProfile.standardArchetypes)
        XCTAssertThrowsError(try emptyDimsCat.validateIntegrity()) {
            XCTAssertEqual($0 as? AssessmentCatalogError, .emptyDimensions)
        }

        // 3. Empty Questions
        let emptyQuestionsCat = AssessmentCatalog(catalogId: "c1", version: "1.0", title: "T", subtitle: "S", description: "D", dimensions: AssessmentDimension.standardDimensions, questions: [], archetypes: ArchetypeProfile.standardArchetypes)
        XCTAssertThrowsError(try emptyQuestionsCat.validateIntegrity()) {
            XCTAssertEqual($0 as? AssessmentCatalogError, .emptyQuestions)
        }

        // 4. Duplicate Dimensions
        let dupDims = [AssessmentDimension.standardDimensions[0], AssessmentDimension.standardDimensions[0]]
        let dupDimCat = AssessmentCatalog(catalogId: "c1", version: "1.0", title: "T", subtitle: "S", description: "D", dimensions: dupDims, questions: [validQ], archetypes: ArchetypeProfile.standardArchetypes)
        XCTAssertThrowsError(try dupDimCat.validateIntegrity()) {
            XCTAssertEqual($0 as? AssessmentCatalogError, .duplicateDimensionIds)
        }

        // 5. Question with unmapped dimension
        let unmappedQ = AssessmentQuestion(id: "q-unmapped", dimensionId: "unknown-dim", type: .likertSlider, title: "Q", prompt: "P")
        let unmappedDimCat = AssessmentCatalog(catalogId: "c1", version: "1.0", title: "T", subtitle: "S", description: "D", dimensions: AssessmentDimension.standardDimensions, questions: [unmappedQ], archetypes: ArchetypeProfile.standardArchetypes)
        XCTAssertThrowsError(try unmappedDimCat.validateIntegrity()) {
            XCTAssertEqual($0 as? AssessmentCatalogError, .unmappedDimension(questionId: "q-unmapped", dimensionId: "unknown-dim"))
        }

        // 6. Empty Archetypes
        let emptyArchetypesCat = AssessmentCatalog(catalogId: "c1", version: "1.0", title: "T", subtitle: "S", description: "D", dimensions: AssessmentDimension.standardDimensions, questions: [validQ], archetypes: [])
        XCTAssertThrowsError(try emptyArchetypesCat.validateIntegrity()) {
            XCTAssertEqual($0 as? AssessmentCatalogError, .emptyArchetypes)
        }

        // 7. Duplicate Archetype IDs
        let dupArchetype = ArchetypeProfile.standardArchetypes[0]
        let dupArchCat = AssessmentCatalog(catalogId: "c1", version: "1.0", title: "T", subtitle: "S", description: "D", dimensions: AssessmentDimension.standardDimensions, questions: [validQ], archetypes: [dupArchetype, dupArchetype])
        XCTAssertThrowsError(try dupArchCat.validateIntegrity()) {
            XCTAssertEqual($0 as? AssessmentCatalogError, .duplicateArchetypeId(archetypeId: dupArchetype.id))
        }
    }

    func testQuestionInvariantEdgeCases() {
        // Empty identifier
        let qEmptyId = AssessmentQuestion(id: "", dimensionId: "arch", type: .likertSlider, title: "T", prompt: "P")
        XCTAssertThrowsError(try qEmptyId.validateInvariants()) {
            XCTAssertEqual($0 as? AssessmentValidationError, .emptyIdentifier)
            XCTAssertNotNil(($0 as? AssessmentValidationError)?.errorDescription)
        }

        // Empty dimension identifier
        let qEmptyDim = AssessmentQuestion(id: "q1", dimensionId: "  ", type: .likertSlider, title: "T", prompt: "P")
        XCTAssertThrowsError(try qEmptyDim.validateInvariants()) {
            XCTAssertEqual($0 as? AssessmentValidationError, .emptyDimensionIdentifier(questionId: "q1"))
        }

        // Choice option with empty ID
        let qChoiceEmptyOptId = AssessmentQuestion(
            id: "qc1", dimensionId: "arch", type: .singleChoice, title: "T", prompt: "P",
            options: [ChoiceOption(id: "  ", title: "T1", scoreWeight: 10), ChoiceOption(id: "opt2", title: "T2", scoreWeight: 20)]
        )
        XCTAssertThrowsError(try qChoiceEmptyOptId.validateInvariants()) {
            XCTAssertEqual($0 as? AssessmentValidationError, .emptyOptionIdentifier(questionId: "qc1"))
        }

        // Choice option with empty Title
        let qChoiceEmptyOptTitle = AssessmentQuestion(
            id: "qc2", dimensionId: "arch", type: .singleChoice, title: "T", prompt: "P",
            options: [ChoiceOption(id: "opt1", title: "", scoreWeight: 10), ChoiceOption(id: "opt2", title: "T2", scoreWeight: 20)]
        )
        XCTAssertThrowsError(try qChoiceEmptyOptTitle.validateInvariants()) {
            XCTAssertEqual($0 as? AssessmentValidationError, .emptyOptionTitle(questionId: "qc2", optionId: "opt1"))
        }

        // Choice option duplicate IDs
        let qChoiceDupOpts = AssessmentQuestion(
            id: "qc3", dimensionId: "arch", type: .singleChoice, title: "T", prompt: "P",
            options: [ChoiceOption(id: "opt1", title: "A", scoreWeight: 10), ChoiceOption(id: "opt1", title: "B", scoreWeight: 20)]
        )
        XCTAssertThrowsError(try qChoiceDupOpts.validateInvariants()) {
            XCTAssertEqual($0 as? AssessmentValidationError, .duplicateOptionIdentifiers(questionId: "qc3"))
        }

        // Short text invalid bounds (min > max or min <= 0)
        let qTextBadBounds = AssessmentQuestion(id: "qt1", dimensionId: "arch", type: .shortText, title: "T", prompt: "P", minCharacters: 50, maxCharacters: 10)
        XCTAssertThrowsError(try qTextBadBounds.validateInvariants()) {
            XCTAssertEqual($0 as? AssessmentValidationError, .invalidTextBounds(questionId: "qt1", min: 50, max: 10))
        }
    }

    func testCatalogLoaderErrorHandling() {
        let loader = LocalCatalogService()

        // 1. Missing file URL read error
        let nonExistentURL = URL(fileURLWithPath: "/tmp/non_existent_path_assessment_test.json")
        XCTAssertThrowsError(try loader.loadCatalog(from: nonExistentURL)) { error in
            guard case CatalogLoaderError.fileReadError = error else {
                XCTFail("Expected fileReadError, got \(error)")
                return
            }
            XCTAssertNotNil((error as? CatalogLoaderError)?.errorDescription)
        }

        // 2. Corrupted JSON decoding failed
        let corruptData = "Not valid JSON content".data(using: .utf8)!
        XCTAssertThrowsError(try loader.decodeCatalog(from: corruptData)) { error in
            guard case CatalogLoaderError.jsonDecodingFailed = error else {
                XCTFail("Expected jsonDecodingFailed, got \(error)")
                return
            }
        }

        // 3. Valid JSON with broken integrity invariants (validation failed)
        let invalidCatalogJSON = """
        {
            "catalogId": "test",
            "version": "1.0",
            "title": "T",
            "subtitle": "S",
            "description": "D",
            "dimensions": [],
            "questions": [],
            "archetypes": []
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try loader.decodeCatalog(from: invalidCatalogJSON)) { error in
            guard case CatalogLoaderError.validationFailed = error else {
                XCTFail("Expected validationFailed, got \(error)")
                return
            }
        }
    }
}
