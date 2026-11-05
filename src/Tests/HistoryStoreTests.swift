import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import AssessYourselfCore

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

    // MARK: - Comparison Service Tests

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
        XCTAssertEqual(archComp.deltaPercentagePoints, 12.0, accuracy: 0.001)
        XCTAssertEqual(archComp.formattedDelta, "+12.0 pp")

        guard let qualComp = comparison.dimensionComparisons.first(where: { $0.dimensionId == "quality" }) else {
            XCTFail("Missing quality comparison")
            return
        }
        XCTAssertEqual(qualComp.deltaPercentagePoints, -5.0, accuracy: 0.001)
        XCTAssertEqual(qualComp.formattedDelta, "-5.0 pp")
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

    // MARK: - ViewModel & UI Tests

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

        let history = try? store.loadHistory()
        XCTAssertEqual(history?.count, 1)
        XCTAssertEqual(history?.first?.id, record.id)
        XCTAssertEqual(history?.first?.overallScore, record.overallScore)
    }

    func testHistoryViewRenderingEmptyAndPopulated() throws {
        // Test Empty State View Rendering
        let emptyView = HistoryView(historyStore: store)
        let _ = emptyView.body

        // Test Populated State View Rendering
        let r1 = createSampleRecord(overallScore: 70.0)
        let r2 = createSampleRecord(overallScore: 82.0)
        try store.save(record: r1)
        try store.save(record: r2)

        let populatedView = HistoryView(historyStore: store)
        let _ = populatedView.body
        XCTAssertEqual(try store.loadHistory().count, 2)
    }
}
