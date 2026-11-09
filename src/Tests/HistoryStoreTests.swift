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
    let targetBounds = CGRect(x: 0, y: 0, width: width, height: height)
    controller.view.frame = targetBounds
    controller.view.layoutIfNeeded()

    let fitted = controller.sizeThatFits(in: CGSize(width: width, height: height))
    if fitted.height > 0 && fitted.width > 0 {
        return fitted
    }
    return controller.view.bounds.size
}
#else
private func renderInHost<V: View>(_ view: V, width: CGFloat = 375, height: CGFloat = 667) -> CGSize {
    return CGSize(width: width, height: height)
}
#endif

// MARK: - Test Doubles

private final class FailingMockHistoryStore: HistoryStoreProtocol, @unchecked Sendable {
    var shouldFail: Bool = true
    var savedRecords: [AssessmentRecord] = []

    func loadHistory() throws -> [AssessmentRecord] {
        if shouldFail {
            throw HistoryStoreError.corruptedData("Simulated read corruption")
        }
        return savedRecords
    }

    func save(record: AssessmentRecord) throws {
        if shouldFail {
            throw HistoryStoreError.storageFailure("Simulated disk I/O failure")
        }
        savedRecords.append(record)
    }

    func clearHistory() throws {
        savedRecords.removeAll()
    }
}

final class HistoryStoreTests: XCTestCase {
    private var testUserDefaults: UserDefaults!
    private var storageKey: String!
    private var store: UserDefaultsHistoryStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let suiteName = "de.iu.assessyourself.tests.\(UUID().uuidString)"
        testUserDefaults = UserDefaults(suiteName: suiteName)!
        storageKey = "test.history.records.\(UUID().uuidString)"
        store = UserDefaultsHistoryStore(
            userDefaults: testUserDefaults,
            storageKey: storageKey,
            maxCapacity: 50
        )
    }

    override func tearDownWithError() throws {
        testUserDefaults.removePersistentDomain(forName: testUserDefaults.description)
        testUserDefaults = nil
        store = nil
        storageKey = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Methods

    private func createSampleRecord(
        id: UUID = UUID(),
        catalogId: String = "software-engineering-ios-v1",
        catalogVersion: String = "1.0.0",
        completedAt: Date = Date(),
        durationSeconds: Double = 120.0,
        overallScore: Double = 80.0,
        dimensionScores: [String: Double] = [
            "architecture": 85.0,
            "quality": 75.0,
            "security": 80.0,
            "performance": 80.0
        ]
    ) -> AssessmentRecord {
        let archetype = ArchetypeProfile(
            id: "system-architect",
            title: "iOS Solution Architect",
            subtitle: "Dominante Dimension: Software Architecture",
            dominantDimensionId: "architecture",
            description: "Exzellente Architekturkompetenz.",
            strengths: ["Modularisierung"],
            growthOpportunities: ["Automatisierte UI-Tests"],
            badgeSymbol: "building.columns.fill"
        )
        return AssessmentRecord(
            id: id,
            catalogId: catalogId,
            catalogVersion: catalogVersion,
            completedAt: completedAt,
            durationSeconds: durationSeconds,
            dimensionScores: dimensionScores,
            overallScore: overallScore,
            archetype: archetype,
            answers: []
        )
    }

    // MARK: - Unit Tests

    func testSaveAndLoadRoundtripPreservesRecord() throws {
        let original = createSampleRecord(overallScore: 84.5)
        try store.save(record: original)

        let loaded = try store.loadHistory()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, original.id)
        XCTAssertEqual(loaded.first?.overallScore, 84.5)
        XCTAssertEqual(loaded.first?.catalogId, original.catalogId)
        XCTAssertEqual(loaded.first?.catalogVersion, "1.0.0")
        XCTAssertEqual(loaded.first?.archetype.title, "iOS Solution Architect")
        XCTAssertEqual(loaded.first?.dimensionScores["architecture"], 85.0)
    }

    func testIdempotentSaveUpdatesExistingRecordWithoutDuplication() throws {
        let recordId = UUID()
        let record1 = createSampleRecord(id: recordId, overallScore: 70.0)
        let record2 = createSampleRecord(id: recordId, overallScore: 92.0)

        try store.save(record: record1)
        XCTAssertEqual(try store.loadHistory().count, 1)
        XCTAssertEqual(try store.loadHistory().first?.overallScore, 70.0)

        try store.save(record: record2)
        let loaded = try store.loadHistory()
        XCTAssertEqual(loaded.count, 1, "Idempotent save must not duplicate entries with the same UUID")
        XCTAssertEqual(loaded.first?.overallScore, 92.0, "Subsequent save with identical UUID must update record")
    }

    func testChronologicalSortingDescendingIndependentOfOverallScore() throws {
        let baseDate = Date()
        // Record 1: Oldest, Highest Score (99%)
        let r1 = createSampleRecord(completedAt: baseDate.addingTimeInterval(-300), overallScore: 99.0)
        // Record 2: Newest, Lowest Score (15%)
        let r2 = createSampleRecord(completedAt: baseDate.addingTimeInterval(0), overallScore: 15.0)
        // Record 3: Intermediate date (Score 50%)
        let r3 = createSampleRecord(completedAt: baseDate.addingTimeInterval(-150), overallScore: 50.0)

        try store.save(record: r1)
        try store.save(record: r2)
        try store.save(record: r3)

        let loaded = try store.loadHistory()
        XCTAssertEqual(loaded.count, 3)
        // Order must be newest first: r2, then r3, then r1
        XCTAssertEqual(loaded[0].id, r2.id, "Newest record must come first")
        XCTAssertEqual(loaded[1].id, r3.id, "Intermediate record must come second")
        XCTAssertEqual(loaded[2].id, r1.id, "Oldest record must come last despite highest score")
    }

    func testFifoCapacityPruningAt50DiscardsOldestRecords() throws {
        let smallStore = UserDefaultsHistoryStore(
            userDefaults: testUserDefaults,
            storageKey: "test.fifo.\(UUID().uuidString)",
            maxCapacity: 50
        )

        let baseDate = Date()
        var insertedIds: [UUID] = []

        // Insert 55 records with monotonically increasing completedAt
        for i in 0..<55 {
            let record = createSampleRecord(
                completedAt: baseDate.addingTimeInterval(Double(i * 60)),
                overallScore: Double(i)
            )
            insertedIds.append(record.id)
            try smallStore.save(record: record)
        }

        let loaded = try smallStore.loadHistory()
        XCTAssertEqual(loaded.count, 50, "Store must strictly prune records exceeding maximum capacity of 50")

        // The 5 oldest records (indices 0..<5) should have been pruned
        let loadedIds = Set(loaded.map(\.id))
        for i in 0..<5 {
            XCTAssertFalse(loadedIds.contains(insertedIds[i]), "Oldest record \(i) should have been evicted by FIFO")
        }
        for i in 5..<55 {
            XCTAssertTrue(loadedIds.contains(insertedIds[i]), "Record \(i) should be retained in the 50 newest")
        }

        // Verify the newest is at index 0
        XCTAssertEqual(loaded.first?.id, insertedIds[54])
    }

    func testCorruptedDataThrowsErrorWithoutWipingStorage() throws {
        // Write invalid data (not JSON decodable as [AssessmentRecord])
        let corruptedString = "{ \"corrupted\": true, \"unclosed\": ["
        testUserDefaults.set(corruptedString.data(using: .utf8), forKey: storageKey)

        XCTAssertThrowsError(try store.loadHistory()) { error in
            guard let historyError = error as? HistoryStoreError else {
                XCTFail("Expected HistoryStoreError, got \(error)")
                return
            }
            if case .corruptedData = historyError {
                // Success
            } else {
                XCTFail("Expected .corruptedData, got \(historyError)")
            }
        }

        // Crucial requirement: Do NOT wipe corrupted data
        let preservedData = testUserDefaults.data(forKey: storageKey)
        XCTAssertNotNil(preservedData, "Corrupted raw data must not be wiped silently")

        // Saving into corrupted store should also throw defensive error
        let freshRecord = createSampleRecord()
        XCTAssertThrowsError(try store.save(record: freshRecord))
    }

    func testClearHistoryRemovesAllEntries() throws {
        try store.save(record: createSampleRecord())
        try store.save(record: createSampleRecord())
        XCTAssertEqual(try store.loadHistory().count, 2)

        try store.clearHistory()
        XCTAssertEqual(try store.loadHistory().count, 0)
    }

    // MARK: - Comparison Service Tests (S7-02, S7-03)

    func testComparisonCalculationInPercentagePoints() {
        let r1 = createSampleRecord(
            overallScore: 68.0,
            dimensionScores: ["architecture": 70.0, "quality": 60.0]
        )
        let r2 = createSampleRecord(
            overallScore: 78.5,
            dimensionScores: ["architecture": 82.0, "quality": 55.0]
        )

        guard let comparison = HistoryComparisonService.compare(current: r2, previous: r1) else {
            XCTFail("Comparison should not be nil")
            return
        }
        XCTAssertEqual(comparison.overallDeltaPercentagePoints, 10.5, accuracy: 0.001)
        XCTAssertEqual(comparison.formattedOverallDelta, "+10.5 pp")

        guard let archComp = comparison.dimensionComparisons.first(where: { $0.dimensionId == "architecture" }) else {
            XCTFail("Missing architecture comparison")
            return
        }
        XCTAssertEqual(archComp.deltaPercentagePoints ?? 0.0, 12.0, accuracy: 0.001)
        XCTAssertEqual(archComp.formattedDelta, "+12.0 pp")

        guard let qualComp = comparison.dimensionComparisons.first(where: { $0.dimensionId == "quality" }) else {
            XCTFail("Missing quality comparison")
            return
        }
        XCTAssertEqual(qualComp.deltaPercentagePoints ?? 0.0, -5.0, accuracy: 0.001)
        XCTAssertEqual(qualComp.formattedDelta, "-5.0 pp")
    }

    func testComparisonHandlesMissingDimensionsWithoutInventingZero() {
        let r1 = createSampleRecord(
            overallScore: 70.0,
            dimensionScores: ["architecture": 70.0, "quality": 60.0]
        )
        let r2 = createSampleRecord(
            overallScore: 80.0,
            dimensionScores: ["architecture": 85.0, "security": 90.0] // quality missing, security new
        )

        guard let comparison = HistoryComparisonService.compare(current: r2, previous: r1) else {
            XCTFail("Comparison should succeed for same catalogId")
            return
        }

        // Architecture is present in both -> valid delta
        let arch = comparison.dimensionComparisons.first(where: { $0.dimensionId == "architecture" })
        XCTAssertEqual(arch?.deltaPercentagePoints ?? 0.0, 15.0, accuracy: 0.001)
        XCTAssertEqual(arch?.formattedDelta, "+15.0 pp")
        XCTAssertTrue(arch?.isComparable == true)

        // Quality is missing in current -> NOT comparable, no fake zero invented
        let qual = comparison.dimensionComparisons.first(where: { $0.dimensionId == "quality" })
        XCTAssertNil(qual?.deltaPercentagePoints, "Missing current dimension must not calculate delta against 0")
        XCTAssertEqual(qual?.formattedDelta, "–")
        XCTAssertFalse(qual?.isComparable == true)

        // Security is missing in previous -> NOT comparable, no fake zero invented
        let sec = comparison.dimensionComparisons.first(where: { $0.dimensionId == "security" })
        XCTAssertNil(sec?.deltaPercentagePoints, "Missing previous dimension must not calculate delta against 0")
        XCTAssertEqual(sec?.formattedDelta, "–")
        XCTAssertFalse(sec?.isComparable == true)
    }

    func testComparisonRejectsIncompatibleCatalogVersions() {
        let r1 = createSampleRecord(catalogId: "catalog-v1", catalogVersion: "1.2.0")
        let r2 = createSampleRecord(catalogId: "catalog-v1", catalogVersion: "2.0.0") // Major mismatch

        XCTAssertFalse(HistoryComparisonService.areVersionsCompatible(lhs: "1.2.0", rhs: "2.0.0"))
        XCTAssertTrue(HistoryComparisonService.areVersionsCompatible(lhs: "1.0.0", rhs: "1.4.1"))

        let comparison = HistoryComparisonService.compare(current: r2, previous: r1)
        XCTAssertNil(comparison, "Assessments with different major catalog versions must not be compared")
    }

    func testComparisonZeroDeltaFormatting() {
        XCTAssertEqual(HistoryComparisonService.formatPercentagePoints(0.0), "0.0 pp")
        XCTAssertEqual(HistoryComparisonService.formatPercentagePoints(0.02), "0.0 pp")
        XCTAssertEqual(HistoryComparisonService.formatPercentagePoints(-0.02), "0.0 pp")
        XCTAssertEqual(HistoryComparisonService.formatPercentagePoints(-3.4), "-3.4 pp")
        XCTAssertEqual(HistoryComparisonService.formatPercentagePoints(5.0), "+5.0 pp")
    }

    func testComparisonRejectsIncompatibleCatalogs() {
        let r1 = createSampleRecord(catalogId: "catalog-v1")
        let r2 = createSampleRecord(catalogId: "catalog-v2")

        let comparison = HistoryComparisonService.compare(current: r2, previous: r1)
        XCTAssertNil(comparison, "Assessments with different catalogId must not be directly compared")
    }

    func testFindPreviousCompatibleRecordAcyclicOnIdenticalCompletedAt() {
        let fixedDate = Date()
        let idA = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let idB = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!

        let rA = createSampleRecord(id: idA, completedAt: fixedDate, overallScore: 80.0)
        let rB = createSampleRecord(id: idB, completedAt: fixedDate, overallScore: 80.0)

        // Under total ordering: rA is newer than rB because idA > idB
        XCTAssertTrue(HistoryComparisonService.isRecordStrictlyOlder(rB, than: rA))
        XCTAssertFalse(HistoryComparisonService.isRecordStrictlyOlder(rA, than: rB))

        let history = [rA, rB]

        // rA looks for previous compatible record -> finds rB
        let foundForA = HistoryComparisonService.findPreviousCompatibleRecord(for: rA, in: history)
        XCTAssertEqual(foundForA?.id, rB.id)

        // rB looks for previous compatible record -> returns nil (must NOT pick rA circularly!)
        let foundForB = HistoryComparisonService.findPreviousCompatibleRecord(for: rB, in: history)
        XCTAssertNil(foundForB, "Preceding record must not circularly pick the subsequent record")
    }

    func testFindPreviousCompatibleRecordInOrderedHistory() {
        let baseDate = Date()
        let rOldest = createSampleRecord(
            catalogId: "standard-v1",
            completedAt: baseDate.addingTimeInterval(-200)
        )
        let rForeign = createSampleRecord(
            catalogId: "other-catalog-v2",
            completedAt: baseDate.addingTimeInterval(-100)
        )
        let rCurrent = createSampleRecord(
            catalogId: "standard-v1",
            completedAt: baseDate
        )

        let history = [rCurrent, rForeign, rOldest]
        let found = HistoryComparisonService.findPreviousCompatibleRecord(for: rCurrent, in: history)
        XCTAssertEqual(found?.id, rOldest.id, "Must skip incompatible foreign catalog and find rOldest")
    }

    func testThreadSafetyUnderConcurrentSaves() {
        let concurrentStore = UserDefaultsHistoryStore(
            userDefaults: testUserDefaults,
            storageKey: "test.concurrency.\(UUID().uuidString)",
            maxCapacity: 50
        )

        let iterations = 30
        let expectation = expectation(description: "Concurrent saves finished")
        expectation.expectedFulfillmentCount = iterations

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let record = self.createSampleRecord(overallScore: Double(i))
            do {
                try concurrentStore.save(record: record)
            } catch {
                XCTFail("Concurrent save failed: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        do {
            let loaded = try concurrentStore.loadHistory()
            XCTAssertEqual(loaded.count, iterations)
        } catch {
            XCTFail("Failed to load history after concurrent saves: \(error)")
        }
    }

    // MARK: - ViewModel & Integration Tests (S7-01, S7-04, S7-05)

    func testViewModelIntegrationAutoSavesCompletedRecordToHistory() {
        let vm = AssessmentViewModel(
            catalogLoader: LocalCatalogService(),
            evaluationEngine: AssessmentEvaluationEngine(),
            hapticService: nil,
            historyStore: store
        )

        vm.loadCatalog()
        guard let catalog = vm.catalog else {
            XCTFail("Failed to load catalog")
            return
        }

        // Fill all 24 questions with valid answers
        for question in catalog.questions {
            switch question.type {
            case .singleChoice:
                vm.recordSingleChoice(questionId: question.id, selectedOptionId: question.options?.first?.id ?? "")
            case .multipleChoice:
                if let firstOpt = question.options?.first?.id {
                    vm.toggleMultipleChoice(questionId: question.id, optionId: firstOpt)
                }
            case .likertSlider:
                vm.recordSliderValue(questionId: question.id, value: 4.0)
            case .shortText:
                vm.recordShortText(questionId: question.id, text: "Architektur und Clean Code im Swift-Projekt.")
            }
            if !vm.isLastQuestion {
                vm.advance()
            }
        }

        vm.submitAssessment()

        guard case .completed(let record) = vm.state else {
            XCTFail("Assessment did not complete successfully")
            return
        }

        XCTAssertNil(vm.persistenceError, "Persistence should succeed on healthy store")
        let history = try? store.loadHistory()
        XCTAssertEqual(history?.count, 1)
        XCTAssertEqual(history?.first?.id, record.id)
        XCTAssertEqual(history?.first?.overallScore, record.overallScore)
    }

    func testViewModelSurfacesPersistenceFailureWithoutLosingRecord() {
        let failingStore = FailingMockHistoryStore()
        failingStore.shouldFail = true

        let vm = AssessmentViewModel(
            catalogLoader: LocalCatalogService(),
            evaluationEngine: AssessmentEvaluationEngine(),
            hapticService: nil,
            historyStore: failingStore
        )

        vm.loadCatalog()
        guard let catalog = vm.catalog else {
            XCTFail("Failed to load catalog")
            return
        }

        // Fill answers
        for question in catalog.questions {
            switch question.type {
            case .singleChoice:
                vm.recordSingleChoice(questionId: question.id, selectedOptionId: question.options?.first?.id ?? "")
            case .multipleChoice:
                if let firstOpt = question.options?.first?.id {
                    vm.toggleMultipleChoice(questionId: question.id, optionId: firstOpt)
                }
            case .likertSlider:
                vm.recordSliderValue(questionId: question.id, value: 4.0)
            case .shortText:
                vm.recordShortText(questionId: question.id, text: "Architektur und Clean Code im Swift-Projekt.")
            }
            if !vm.isLastQuestion {
                vm.advance()
            }
        }

        vm.submitAssessment()

        // Evaluated record must NOT be lost!
        guard case .completed(let record) = vm.state else {
            XCTFail("Evaluated record must be preserved even if saving failed")
            return
        }
        XCTAssertEqual(record.catalogId, "devprofile-se-2026")

        // Persistence error must be surfaced explicitly
        XCTAssertNotNil(vm.persistenceError, "Persistence error must be surfaced to user")
        XCTAssertTrue(vm.persistenceError?.contains("Simulated disk I/O failure") == true)

        // Test Recovery: heal the store and retry
        failingStore.shouldFail = false
        let recovered = vm.retryPersistence()
        XCTAssertTrue(recovered, "Retrying persistence after store recovery must succeed")
        XCTAssertNil(vm.persistenceError, "Persistence error must be cleared upon successful retry")
        XCTAssertEqual(failingStore.savedRecords.count, 1)
    }

    @MainActor
    func testHistoryViewHostingLifecycleAndStateTransitions() throws {
        // 1. Empty State Rendering
        let emptyView = HistoryView(historyStore: store)
        emptyView.loadRecords()
        let emptySize = renderInHost(emptyView)
        XCTAssertGreaterThan(emptySize.width, 0)
        XCTAssertGreaterThan(emptySize.height, 0)

        // 2. Populated State Rendering with Delta Comparison
        let r1 = createSampleRecord(overallScore: 70.0)
        let r2 = createSampleRecord(overallScore: 82.0)
        try store.save(record: r1)
        try store.save(record: r2)

        let populatedView = HistoryView(historyStore: store)
        populatedView.loadRecords()
        let populatedSize = renderInHost(populatedView)
        XCTAssertGreaterThan(populatedSize.width, 0)
        XCTAssertGreaterThan(populatedSize.height, 0)
        XCTAssertEqual(try store.loadHistory().count, 2)

        // 3. Error State and Corruption Reset Path (S7-05)
        let corruptKey = "test.corrupt.view.\(UUID().uuidString)"
        let corruptedStore = UserDefaultsHistoryStore(
            userDefaults: testUserDefaults,
            storageKey: corruptKey,
            maxCapacity: 50
        )
        // Corrupt storage with invalid data using the EXACT same storage key
        testUserDefaults.set("invalid-json-payload".data(using: .utf8), forKey: corruptKey)

        let errorView = HistoryView(historyStore: corruptedStore)
        errorView.loadRecords() // Fails gracefully with corruptedData
        XCTAssertNotNil(errorView.currentErrorMessage, "Corrupted storage must trigger error state message")
        XCTAssertTrue(errorView.currentErrorMessage?.contains("corruptedData") == true || errorView.currentErrorMessage?.contains("decode") == true)

        let errorSize = renderInHost(errorView)
        XCTAssertGreaterThan(errorSize.width, 0)
        XCTAssertGreaterThan(errorSize.height, 0)

        // Verify alert flow: user requests reset dialog
        errorView.requestResetCorrupted()
        XCTAssertEqual(errorView.currentActiveAlert?.id, HistoryView.HistoryAlertItem.resetCorrupted.id)

        // Scenario A: User cancels alert -> storage and error remain intact
        errorView.dismissAlert()
        XCTAssertNil(errorView.currentActiveAlert)
        XCTAssertNotNil(errorView.currentErrorMessage, "Dismissing alert must not clear error message")
        XCTAssertThrowsError(try corruptedStore.loadHistory(), "Store remains corrupted after cancel")

        // Scenario B: User confirms reset -> store is cleared, error is reset, count becomes 0
        errorView.requestResetCorrupted()
        errorView.confirmActiveAlert()
        XCTAssertNil(errorView.currentActiveAlert)
        XCTAssertNil(errorView.currentErrorMessage, "Confirming reset must clear error state")
        XCTAssertEqual(errorView.displayedRecordsCount, 0, "Display count must be zero after corruption reset")
        XCTAssertEqual(try corruptedStore.loadHistory().count, 0, "Underlying store must be completely wiped")
    }

    @MainActor
    func testCompleteAssessmentPersistsAndSurvivesStoreReinstantiation() throws {
        let isolatedKey = "test.lifecycle.relaunch.\(UUID().uuidString)"
        let initialStore = UserDefaultsHistoryStore(
            userDefaults: testUserDefaults,
            storageKey: isolatedKey,
            maxCapacity: 50
        )

        // 1. Load catalog & complete assessment via AssessmentViewModel
        let vm = AssessmentViewModel(
            catalogLoader: CatalogLoader(),
            evaluationEngine: EvaluationEngine(),
            historyStore: initialStore
        )
        vm.loadCatalog()

        guard let questions = vm.catalog?.questions else {
            XCTFail("Catalog must be loaded")
            return
        }

        for (idx, question) in questions.enumerated() {
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
                let sampleText = "Praxiseinsatz mit sauberer Software-Architektur und testgetriebener Entwicklung."
                vm.recordShortText(questionId: question.id, text: sampleText)
            }

            if idx < questions.count - 1 {
                vm.advance()
            }
        }

        XCTAssertTrue(vm.isLastQuestion)
        XCTAssertTrue(vm.isCurrentAnswerValid)
        vm.submitAssessment()
        guard case .completed = vm.state else {
            XCTFail("AssessmentViewModel state must be .completed after submit")
            return
        }
        XCTAssertNil(vm.persistenceError, "Save must succeed without persistence error")

        // Verify initial save
        let initialRecords = try initialStore.loadHistory()
        XCTAssertEqual(initialRecords.count, 1)
        let savedRecord = initialRecords[0]
        XCTAssertEqual(savedRecord.catalogId, "devprofile-se-2026")
        XCTAssertEqual(savedRecord.catalogVersion, "1.0.0")
        XCTAssertFalse(savedRecord.archetype.title.isEmpty)

        // 2. Simulate App Relaunch by creating a fresh store with the SAME storageKey
        let relaunchedStore = UserDefaultsHistoryStore(
            userDefaults: testUserDefaults,
            storageKey: isolatedKey,
            maxCapacity: 50
        )
        let relaunchedRecords = try relaunchedStore.loadHistory()
        XCTAssertEqual(relaunchedRecords.count, 1, "Relaunched store must contain exactly 1 persisted record")
        XCTAssertEqual(relaunchedRecords[0].id, savedRecord.id)
        XCTAssertEqual(relaunchedRecords[0].overallScore, savedRecord.overallScore)
        XCTAssertEqual(relaunchedRecords[0].archetype.title, savedRecord.archetype.title)
        XCTAssertEqual(relaunchedRecords[0].dimensionScores, savedRecord.dimensionScores)

        // 3. Verify HistoryView displays this persisted record upon launch
        let historyView = HistoryView(historyStore: relaunchedStore)
        historyView.loadRecords()
        XCTAssertEqual(historyView.displayedRecordsCount, 1)
        XCTAssertNil(historyView.currentErrorMessage)

        let hostedSize = renderInHost(historyView)
        XCTAssertGreaterThan(hostedSize.width, 0)
        XCTAssertGreaterThan(hostedSize.height, 0)
    }
}
