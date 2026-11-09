import XCTest
import SwiftUI
@testable import AssessYourselfCore

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

final class CatalogManagerTests: XCTestCase {
    private var temporaryDirectoryURL: URL!
    private var mockLoader: LocalCatalogService!
    private var sutStore: SandboxCatalogStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CatalogManagerTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
        mockLoader = LocalCatalogService()
        sutStore = SandboxCatalogStore(baseURL: temporaryDirectoryURL, catalogLoader: mockLoader)
    }

    override func tearDownWithError() throws {
        if let dir = temporaryDirectoryURL, FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }
        temporaryDirectoryURL = nil
        mockLoader = nil
        sutStore = nil
        try super.tearDownWithError()
    }

    // MARK: - SandboxCatalogStore Tests

    func testSandboxCatalogStoreLoadsBundledByDefault() throws {
        XCTAssertFalse(sutStore.hasCustomCatalog)
        let catalog = try sutStore.loadActiveCatalog()
        XCTAssertEqual(catalog.catalogId, "devprofile-se-2026")
        XCTAssertEqual(catalog.questions.count, 24)
        XCTAssertFalse(sutStore.hasCustomCatalog)
    }

    func testSandboxCatalogStoreSavesAndPersistsCustomCatalog() throws {
        let baseCatalog = try sutStore.loadActiveCatalog()
        let customQuestion = AssessmentQuestion(
            id: "q_test_custom_01",
            dimensionId: "architecture",
            type: .likertSlider,
            title: "Architektur-Modularisierung",
            prompt: "Wie modular gliedern Sie Systemmodule?",
            sliderMin: 1.0,
            sliderMax: 5.0,
            sliderStep: 1.0,
            sliderMinLabel: "Gering",
            sliderMaxLabel: "Hoch",
            sliderDefault: 3.0
        )

        let modifiedCatalog = try baseCatalog.addingQuestion(customQuestion)
        try sutStore.saveCustomCatalog(modifiedCatalog)

        XCTAssertTrue(sutStore.hasCustomCatalog)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sutStore.activeFileURL.path))

        // Reload from disk
        let reloaded = try sutStore.loadActiveCatalog()
        XCTAssertEqual(reloaded.questions.count, 25)
        XCTAssertTrue(reloaded.questions.contains(where: { $0.id == "q_test_custom_01" }))
    }

    func testSandboxCatalogStoreCreatesBakBackupOnOverwrite() throws {
        let baseCatalog = try sutStore.loadActiveCatalog()
        let q1 = AssessmentQuestion(
            id: "q_custom_first",
            dimensionId: "architecture",
            type: .likertSlider,
            title: "First Custom",
            prompt: "Prompt 1",
            sliderMin: 1, sliderMax: 5, sliderStep: 1, sliderDefault: 3
        )
        let catV1 = try baseCatalog.addingQuestion(q1)
        try sutStore.saveCustomCatalog(catV1)

        XCTAssertFalse(FileManager.default.fileExists(atPath: sutStore.backupFileURL.path), "Backup should not exist on first save")

        let q2 = AssessmentQuestion(
            id: "q_custom_second",
            dimensionId: "platform",
            type: .likertSlider,
            title: "Second Custom",
            prompt: "Prompt 2",
            sliderMin: 1, sliderMax: 5, sliderStep: 1, sliderDefault: 3
        )
        let catV2 = try catV1.addingQuestion(q2)
        try sutStore.saveCustomCatalog(catV2)

        XCTAssertTrue(FileManager.default.fileExists(atPath: sutStore.backupFileURL.path), "Backup must exist after second save")

        // Backup file must contain catV1 (25 questions), while active contains catV2 (26 questions)
        let backupData = try Data(contentsOf: sutStore.backupFileURL)
        let decodedBackup = try mockLoader.decodeCatalog(from: backupData)
        XCTAssertEqual(decodedBackup.questions.count, 25)
        XCTAssertTrue(decodedBackup.questions.contains(where: { $0.id == "q_custom_first" }))
        XCTAssertFalse(decodedBackup.questions.contains(where: { $0.id == "q_custom_second" }))
    }

    func testSandboxCatalogStoreRollbackToBakWhenActiveCorrupted() throws {
        let baseCatalog = try sutStore.loadActiveCatalog()
        let q1 = AssessmentQuestion(
            id: "q_rollback_test",
            dimensionId: "quality",
            type: .likertSlider,
            title: "Rollback Question",
            prompt: "Prompt",
            sliderMin: 1, sliderMax: 5, sliderStep: 1, sliderDefault: 3
        )
        let customCat = try baseCatalog.addingQuestion(q1)
        try sutStore.saveCustomCatalog(customCat)

        // Save second version to generate .bak
        let q2 = AssessmentQuestion(
            id: "q_second_version",
            dimensionId: "agile",
            type: .likertSlider,
            title: "Second Version",
            prompt: "Prompt",
            sliderMin: 1, sliderMax: 5, sliderStep: 1, sliderDefault: 3
        )
        let customCat2 = try customCat.addingQuestion(q2)
        try sutStore.saveCustomCatalog(customCat2)

        // Corrupt active file
        try Data("CORRUPTED_JSON_DATA_NON_PARSABLE".utf8).write(to: sutStore.activeFileURL)

        // Loading must trigger rollback and throw corruptedRollbackTriggered
        XCTAssertThrowsError(try sutStore.loadActiveCatalog()) { error in
            guard case SandboxCatalogError.corruptedRollbackTriggered = error else {
                XCTFail("Expected corruptedRollbackTriggered but received: \(error)")
                return
            }
        }

        // After rollback, the active file must be restored from .bak (containing q_rollback_test)
        let restored = try sutStore.loadActiveCatalog()
        XCTAssertEqual(restored.questions.count, 25)
        XCTAssertTrue(restored.questions.contains(where: { $0.id == "q_rollback_test" }))
    }

    func testSandboxCatalogStoreFailsGracefullyWhenBothCorrupted() throws {
        let baseCatalog = try sutStore.loadActiveCatalog()
        let q1 = AssessmentQuestion(
            id: "q_both_corrupt",
            dimensionId: "quality",
            type: .likertSlider,
            title: "Title",
            prompt: "Prompt",
            sliderMin: 1, sliderMax: 5, sliderStep: 1, sliderDefault: 3
        )
        try sutStore.saveCustomCatalog(try baseCatalog.addingQuestion(q1))
        try sutStore.saveCustomCatalog(baseCatalog) // creates .bak

        // Corrupt both active and backup files
        try Data("CORRUPT_ACTIVE".utf8).write(to: sutStore.activeFileURL)
        try Data("CORRUPT_BACKUP".utf8).write(to: sutStore.backupFileURL)

        XCTAssertThrowsError(try sutStore.loadActiveCatalog()) { error in
            guard case SandboxCatalogError.corruptedRollbackFailed = error else {
                XCTFail("Expected corruptedRollbackFailed but received: \(error)")
                return
            }
        }
    }

    func testSandboxCatalogStoreFailsWhenActiveCorruptedAndNoBackup() throws {
        let baseCatalog = try sutStore.loadActiveCatalog()
        try sutStore.saveCustomCatalog(baseCatalog)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sutStore.backupFileURL.path))

        // Corrupt active file
        try Data("CORRUPT_ACTIVE_NO_BAK".utf8).write(to: sutStore.activeFileURL)

        XCTAssertThrowsError(try sutStore.loadActiveCatalog()) { error in
            guard case SandboxCatalogError.corruptedNoBackup = error else {
                XCTFail("Expected corruptedNoBackup but received: \(error)")
                return
            }
        }
    }

    func testSandboxCatalogStoreResetDeletesFiles() throws {
        let baseCatalog = try sutStore.loadActiveCatalog()
        try sutStore.saveCustomCatalog(baseCatalog)
        try sutStore.saveCustomCatalog(baseCatalog) // creates .bak

        XCTAssertTrue(FileManager.default.fileExists(atPath: sutStore.activeFileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sutStore.backupFileURL.path))

        try sutStore.resetToBundledCatalog()

        XCTAssertFalse(FileManager.default.fileExists(atPath: sutStore.activeFileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: sutStore.backupFileURL.path))
        XCTAssertFalse(sutStore.hasCustomCatalog)
    }

    func testSandboxCatalogStoreRejectsInvalidCatalog() throws {
        let invalidCatalog = AssessmentCatalog(
            catalogId: "", // invalid empty ID
            version: "1.0",
            title: "Invalid",
            subtitle: "Sub",
            description: "Desc",
            dimensions: [],
            questions: [],
            archetypes: []
        )

        XCTAssertThrowsError(try sutStore.saveCustomCatalog(invalidCatalog)) { error in
            guard case SandboxCatalogError.catalogValidationFailed = error else {
                XCTFail("Expected catalogValidationFailed, got \(error)")
                return
            }
        }
    }

    func testSandboxCatalogStoreImportValidAndMalformedData() throws {
        let baseCatalog = try sutStore.loadActiveCatalog()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let validData = try encoder.encode(baseCatalog)

        let imported = try sutStore.importCatalog(from: validData)
        XCTAssertEqual(imported.catalogId, baseCatalog.catalogId)
        XCTAssertTrue(sutStore.hasCustomCatalog)

        let malformedData = Data("{ \"catalogId\": \"incomplete\" }".utf8)
        XCTAssertThrowsError(try sutStore.importCatalog(from: malformedData)) { error in
            guard case SandboxCatalogError.catalogValidationFailed = error else {
                XCTFail("Expected catalogValidationFailed for malformed import, got \(error)")
                return
            }
        }
    }

    // MARK: - CatalogManagerViewModel Tests

    func testCatalogManagerViewModelInitialization() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        XCTAssertEqual(vm.totalQuestionsCount, 24)
        XCTAssertFalse(vm.hasCustomCatalog)
        XCTAssertEqual(vm.dimensions.count, 4)
        XCTAssertNil(vm.selectedDimensionFilter)
        XCTAssertEqual(vm.filteredQuestions.count, 24)
    }

    func testCatalogManagerViewModelFormValidation() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        vm.resetForm()
        XCTAssertFalse(vm.isFormValid, "Empty title and prompt must be invalid")

        vm.formTitle = "Valid Title"
        vm.formPrompt = "Valid Prompt"
        XCTAssertTrue(vm.isFormValid, "Valid single choice inputs must satisfy validation")

        // Duplicate question ID must be rejected
        vm.formQuestionId = "arch-sc-01" // existing ID in bundled catalog
        XCTAssertFalse(vm.isFormValid, "Duplicate ID must be rejected")
    }

    func testCatalogManagerViewModelAddNewSingleChoiceQuestion() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        vm.resetForm()
        vm.formQuestionId = "q_sc_new"
        vm.formDimensionId = "architecture"
        vm.formType = .singleChoice
        vm.formTitle = "Neue Single-Choice Frage"
        vm.formPrompt = "Welche Architektur wählen Sie?"
        vm.formOption1Title = "Option A"
        vm.formOption1Score = 50.0
        vm.formOption2Title = "Option B"
        vm.formOption2Score = 100.0

        let success = vm.saveNewQuestion()
        XCTAssertTrue(success)
        XCTAssertEqual(vm.totalQuestionsCount, 25)
        XCTAssertTrue(vm.hasCustomCatalog)
        XCTAssertNotNil(vm.statusMessage)
        XCTAssertTrue(vm.questions.contains(where: { $0.id == "q_sc_new" }))
    }

    func testCatalogManagerViewModelAddNewSliderQuestion() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        vm.resetForm()
        vm.formQuestionId = "q_slider_new"
        vm.formDimensionId = "platform"
        vm.formType = .likertSlider
        vm.formTitle = "SwiftUI Expertise"
        vm.formPrompt = "Bewerten Sie Ihre Beherrschung von View-Trees."
        vm.formSliderMin = 1.0
        vm.formSliderMax = 5.0
        vm.formSliderStep = 1.0
        vm.formSliderMinLabel = "Einsteiger"
        vm.formSliderMaxLabel = "Experte"

        let success = vm.saveNewQuestion()
        XCTAssertTrue(success)
        XCTAssertEqual(vm.totalQuestionsCount, 25)
        let added = vm.questions.first(where: { $0.id == "q_slider_new" })
        XCTAssertEqual(added?.type, .likertSlider)
        XCTAssertEqual(added?.sliderMax, 5.0)
    }

    func testCatalogManagerViewModelAddNewShortTextQuestion() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        vm.resetForm()
        vm.formQuestionId = "q_text_new"
        vm.formDimensionId = "quality"
        vm.formType = .shortText
        vm.formTitle = "Teststrategie Begründung"
        vm.formPrompt = "Erläutern Sie Ihre Unit-Test-Pyramide."
        vm.formMinCharacters = 20
        vm.formMaxCharacters = 300

        let success = vm.saveNewQuestion()
        XCTAssertTrue(success)
        XCTAssertEqual(vm.totalQuestionsCount, 25)
        let added = vm.questions.first(where: { $0.id == "q_text_new" })
        XCTAssertEqual(added?.type, .shortText)
        XCTAssertEqual(added?.minCharacters, 20)
    }

    func testCatalogManagerViewModelDeleteQuestion() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        // Add a question first
        vm.resetForm()
        vm.formQuestionId = "q_to_delete"
        vm.formDimensionId = "agile"
        vm.formType = .likertSlider
        vm.formTitle = "Zu löschen"
        vm.formPrompt = "Prompt"
        XCTAssertTrue(vm.saveNewQuestion())
        XCTAssertEqual(vm.totalQuestionsCount, 25)

        // Delete the question
        let deleted = vm.deleteQuestion(id: "q_to_delete")
        XCTAssertTrue(deleted)
        XCTAssertEqual(vm.totalQuestionsCount, 24)
        XCTAssertFalse(vm.questions.contains(where: { $0.id == "q_to_delete" }))
    }

    func testCatalogManagerViewModelResetToBundled() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        vm.resetForm()
        vm.formQuestionId = "q_temp_custom"
        vm.formDimensionId = "architecture"
        vm.formType = .likertSlider
        vm.formTitle = "Temp"
        vm.formPrompt = "Temp Prompt"
        _ = vm.saveNewQuestion()
        XCTAssertTrue(vm.hasCustomCatalog)

        let resetSuccess = vm.resetToBundledCatalog()
        XCTAssertTrue(resetSuccess)
        XCTAssertFalse(vm.hasCustomCatalog)
        XCTAssertEqual(vm.totalQuestionsCount, 24)
    }

    func testCatalogManagerViewModelImportAndExportJSON() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        guard let jsonString = vm.exportCatalogJSON() else {
            XCTFail("Exporting JSON must return valid string")
            return
        }
        XCTAssertTrue(jsonString.contains("devprofile-se-2026"))

        // Re-import exported string
        let imported = vm.importCatalogJSON(jsonString)
        XCTAssertTrue(imported)
        XCTAssertEqual(vm.totalQuestionsCount, 24)

        // Attempt malformed import
        let failed = vm.importCatalogJSON("invalid json syntax")
        XCTAssertFalse(failed)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - SwiftUI View Hosting Lifecycle Tests

    @MainActor
    func testCatalogManagerViewHostingOnPhoneAndIPad() {
        let vm = CatalogManagerViewModel(catalogStore: sutStore, hapticService: nil)
        let view = CatalogManagerView(viewModel: vm)
            .appTheme(AppTheme.standard)

        #if canImport(AppKit)
        let phoneView = NSHostingView(rootView: view)
        phoneView.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        phoneView.layout()
        XCTAssertGreaterThan(phoneView.fittingSize.width, 0)

        let padView = NSHostingView(rootView: view)
        padView.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        padView.layout()
        XCTAssertGreaterThan(padView.fittingSize.width, 0)
        #elseif canImport(UIKit)
        let phoneController = UIHostingController(rootView: view)
        phoneController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        phoneController.loadViewIfNeeded()
        XCTAssertNotNil(phoneController.view)

        let padController = UIHostingController(rootView: view)
        padController.view.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        padController.loadViewIfNeeded()
        XCTAssertNotNil(padController.view)
        #endif
    }
}
