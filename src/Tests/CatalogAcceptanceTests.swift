import Foundation
import XCTest
@testable import AssessYourselfCore

/// Independent acceptance tests verifying catalog domain invariants,
/// transactional sandbox backup resilience, UI rendering limits, and historical comparability.
final class CatalogAcceptanceTests: XCTestCase {

    private func withTemporarySandboxStore(_ block: (SandboxCatalogStore) throws -> Void) throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("dlamsd02_test_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let store = SandboxCatalogStore(baseURL: tempDir)
        try block(store)
    }

    private func alteredCatalog(_ base: AssessmentCatalog, inserting first: AssessmentQuestion) throws -> AssessmentCatalog {
        try base.addingQuestion(first).removingQuestion(id: base.questions[0].id)
    }

    // MARK: - Numeric Rendering Resilience

    /// Verifies that extreme floating-point values within finite range
    /// do not trigger an integer overflow trap when rendered in LikertSliderCard.
    @MainActor
    func testAcceptedLargeSliderCanRenderWithoutOverflowCrash() throws {
        let baseCatalog = try LocalCatalogService().loadBundledCatalog()
        let largeSliderQuestion = AssessmentQuestion(
            id: "probe-overflow",
            dimensionId: baseCatalog.questions[0].dimensionId,
            type: .likertSlider,
            title: "Large Slider Bounds Audit",
            prompt: "Bewerten Sie den Einfluss bei extremen Skalenwerten.",
            sliderMin: 1.0,
            sliderMax: 1e20,
            sliderStep: 1.0,
            sliderDefault: 3.0
        )

        let customCatalog = try baseCatalog.addingQuestion(largeSliderQuestion)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = SandboxCatalogStore(baseURL: tempDir)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imported = try store.importCatalog(from: JSONEncoder().encode(customCatalog))
        let importedQuestion = try XCTUnwrap(imported.questions.last)

        let card = LikertSliderCard(
            value: 3.0,
            minVal: try XCTUnwrap(importedQuestion.sliderMin),
            maxVal: try XCTUnwrap(importedQuestion.sliderMax),
            step: try XCTUnwrap(importedQuestion.sliderStep),
            minLabel: "Gering",
            maxLabel: "Hoch",
            dimensionId: importedQuestion.dimensionId,
            onValueChange: { _ in }
        )

        // Rendering the body evaluates safeNumberString without runtime integer overflow
        XCTAssertNotNil(card.body)
    }

    // MARK: - Assessment Flow Initial Step Snapping

    /// Verifies that when an imported slider specifies a default value that sits off-grid
    /// (e.g. min 1, step 2, default 2), the flow view model snaps the initial answer
    /// to a valid step grid increment (e.g. 3) so that `isCurrentAnswerValid` is immediately true.
    @MainActor
    func testImportedSliderStartsWithAnswerAcceptedByFlow() throws {
        try withTemporarySandboxStore { store in
            let base = try store.loadActiveCatalog()
            let offGridQuestion = AssessmentQuestion(
                id: "probe-off-grid",
                dimensionId: base.questions[0].dimensionId,
                type: .likertSlider,
                title: "Off-Grid Default Audit",
                prompt: "Skalenwert mit nicht-ganzzahligem Schrittversatz.",
                sliderMin: 1.0,
                sliderMax: 5.0,
                sliderStep: 2.0,
                sliderDefault: 2.0
            )

            let altered = try alteredCatalog(base, inserting: offGridQuestion)
            let ordered = AssessmentCatalog(
                catalogId: altered.catalogId,
                version: altered.version,
                title: altered.title,
                subtitle: altered.subtitle,
                description: altered.description,
                dimensions: altered.dimensions,
                questions: [offGridQuestion] + altered.questions.dropLast(),
                archetypes: altered.archetypes
            )

            _ = try store.importCatalog(from: JSONEncoder().encode(ordered))
            let vm = AssessmentViewModel(hapticService: nil, catalogStore: store)
            vm.loadCatalog()

            XCTAssertEqual(vm.currentQuestion?.id, offGridQuestion.id)
            XCTAssertTrue(vm.isCurrentAnswerValid, "Der Startwert muss im gültigen Schrittgitter liegen und sofort validieren.")
        }
    }

    // MARK: - Longitudinal Comparability & SemVer

    /// Verifies that structurally altering the question battery (adding or removing questions)
    /// increments the major version of the catalog, effectively disallowing direct delta
    /// comparisons across incompatible measurement instruments.
    func testCompatibleHistoryRequiresUnchangedQuestionSet() throws {
        let baseCatalog = try LocalCatalogService().loadBundledCatalog()
        let additionalQuestion = AssessmentQuestion(
            id: "probe-history-extra",
            dimensionId: baseCatalog.questions[0].dimensionId,
            type: .likertSlider,
            title: "Zusätzliche Frage für Instrumentenvergleich",
            prompt: "Prüfung der longitudinalen Vergleichbarkeit.",
            sliderMin: 1.0,
            sliderMax: 5.0,
            sliderStep: 1.0,
            sliderDefault: 5.0
        )

        let modifiedCatalog = try baseCatalog.addingQuestion(additionalQuestion)
        XCTAssertNotEqual(baseCatalog.version, modifiedCatalog.version)

        func makeRecord(for catalog: AssessmentCatalog, score: Double) -> AssessmentRecord {
            AssessmentRecord(
                catalogId: catalog.catalogId,
                catalogVersion: catalog.version,
                completedAt: Date(),
                durationSeconds: 120,
                dimensionScores: [additionalQuestion.dimensionId: score],
                overallScore: score,
                archetype: catalog.archetypes[0],
                answers: []
            )
        }

        let comparison = HistoryComparisonService.compare(
            current: makeRecord(for: modifiedCatalog, score: 75.0),
            previous: makeRecord(for: baseCatalog, score: 65.0)
        )

        XCTAssertNil(comparison, "Veränderte Fragenkataloge dürfen keine irreführenden Deltas erzeugen.")
    }

    // MARK: - Transactional Sandbox Backup Resilience

    /// Verifies that an atomic catalog import does not overwrite a valid `.bak` backup
    /// with corrupted active bytes if the active file on disk was corrupted before import.
    func testValidImportPreservesLastGoodBackupWhenActiveIsCorrupt() throws {
        try withTemporarySandboxStore { store in
            let baseCatalog = try store.loadActiveCatalog()
            try store.saveCustomCatalog(baseCatalog)
            try store.saveCustomCatalog(baseCatalog)

            let knownGoodBackup = try Data(contentsOf: store.backupFileURL)
            let corruptedActiveBytes = Data("corrupted-json-payload-dlamsd02".utf8)
            try corruptedActiveBytes.write(to: store.activeFileURL, options: .atomic)

            let freshPayload = try JSONEncoder().encode(baseCatalog)
            _ = try store.importCatalog(from: freshPayload)

            let currentBackup = try Data(contentsOf: store.backupFileURL)
            XCTAssertEqual(knownGoodBackup, currentBackup, "Ein valider Import darf das wiederherstellbare .bak nicht mit beschädigten Daten überschreiben.")
            XCTAssertNotEqual(currentBackup, corruptedActiveBytes)
        }
    }

    // MARK: - Dynamic Filter State Reset

    /// Verifies that resetting the catalog to bundled defaults automatically resets any active
    /// dimension filter if that dimension only existed in the previously imported custom catalog.
    @MainActor
    func testResetClearsFilterForDimensionOnlyInImportedCatalog() throws {
        try withTemporarySandboxStore { store in
            let vm = CatalogManagerViewModel(catalogStore: store, hapticService: nil)
            let bundledCatalog = try store.loadActiveCatalog()
            let baseJSON = try XCTUnwrap(String(data: JSONEncoder().encode(bundledCatalog), encoding: .utf8))
            let customJSON = baseJSON.replacingOccurrences(of: "\"architecture\"", with: "\"probe-custom-dimension\"")

            XCTAssertTrue(vm.importCatalogJSON(customJSON))
            vm.selectedDimensionFilter = "probe-custom-dimension"
            XCTAssertFalse(vm.filteredQuestions.isEmpty)

            XCTAssertTrue(vm.resetToBundledCatalog())
            XCTAssertEqual(vm.filteredQuestions.count, bundledCatalog.questions.count, "Der Filter für eine entfernte Dimension muss zurückgesetzt werden.")
            XCTAssertNil(vm.selectedDimensionFilter)
        }
    }
}
