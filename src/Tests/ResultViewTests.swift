import XCTest
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import AssessYourselfCore

final class ResultViewTests: XCTestCase {

    private func renderInHost<V: View>(_ view: V, proposed: CGSize = CGSize(width: 393, height: 852)) -> CGSize {
        #if os(iOS)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: proposed)
        let fitted = controller.sizeThatFits(in: proposed)
        if fitted.width > 0 && fitted.height > 0 {
            return fitted
        }
        let systemFit = controller.view.systemLayoutSizeFitting(
            proposed,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if systemFit.width > 0 && systemFit.height > 0 {
            return systemFit
        }
        return .zero
        #elseif os(macOS)
        let controller = NSHostingController(rootView: view)
        controller.view.setFrameSize(proposed)
        let size = controller.view.fittingSize
        return size.width > 0 && size.height > 0 ? size : .zero
        #else
        return proposed
        #endif
    }

    // MARK: - DimensionScoreBarView Tests

    func testDimensionScoreBarViewNormalizedRatioAndFormatting() {
        let bar1 = DimensionScoreBarView(
            dimensionId: "architecture",
            title: "Software Architecture",
            iconSystemName: "building.columns.fill",
            score: 75.0
        )
        XCTAssertEqual(bar1.normalizedRatio, 0.75, accuracy: 0.001)
        XCTAssertEqual(bar1.formattedScore, "75.0 %")

        // Bounds clamping
        let barNegative = DimensionScoreBarView(
            dimensionId: "platform",
            title: "Platform",
            iconSystemName: "apple.logo",
            score: -15.0
        )
        XCTAssertEqual(barNegative.normalizedRatio, 0.0)
        XCTAssertEqual(barNegative.formattedScore, "0.0 %")

        let barOverflow = DimensionScoreBarView(
            dimensionId: "quality",
            title: "Quality",
            iconSystemName: "checkmark.seal.fill",
            score: 125.0
        )
        XCTAssertEqual(barOverflow.normalizedRatio, 1.0)
        XCTAssertEqual(barOverflow.formattedScore, "100.0 %")
    }

    func testDimensionScoreBarViewRendering() {
        let bar = DimensionScoreBarView(
            dimensionId: "agile",
            title: "Agile Engineering",
            iconSystemName: "arrow.triangle.2.circlepath",
            score: 88.5
        )
        let size = renderInHost(bar)
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    // MARK: - ArchetypeCardView Tests

    func testArchetypeCardViewPresentationAndClamping() {
        let archetype = ArchetypeProfile.standardArchetypes[0]
        let card = ArchetypeCardView(
            archetype: archetype,
            overallScore: 84.5
        )
        XCTAssertEqual(card.overallScore, 84.5)

        // Clamping check
        let cardNegative = ArchetypeCardView(archetype: archetype, overallScore: -50.0)
        XCTAssertEqual(cardNegative.overallScore, 0.0)

        let cardOverflow = ArchetypeCardView(archetype: archetype, overallScore: 150.0)
        XCTAssertEqual(cardOverflow.overallScore, 100.0)

        let size = renderInHost(card)
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    func testArchetypeCardViewWithEmptyStrengthsAndOpportunities() {
        let minimalArchetype = ArchetypeProfile(
            id: "minimal",
            title: "Minimalist",
            subtitle: "Generalist",
            dominantDimensionId: "architecture",
            description: "A minimal archetype profile for boundary testing.",
            strengths: [],
            growthOpportunities: [],
            badgeSymbol: "star.fill"
        )
        let card = ArchetypeCardView(archetype: minimalArchetype, overallScore: 50.0)
        let size = renderInHost(card)
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    // MARK: - PedagogicalRecommendationsView Tests

    func testPedagogicalRecommendationsGenerationAndPriority() {
        let scores: [String: Double] = [
            "architecture": 45.0, // High priority (<60)
            "platform": 72.0,     // Recommended (<80)
            "quality": 90.0,      // Deepening (>=80)
            "agile": 82.0
        ]
        let recView = PedagogicalRecommendationsView(dimensionScores: scores)
        let recommendations = recView.recommendations

        XCTAssertEqual(recommendations.count, 4)
        // Architecture had the lowest score, so it must be ranked first
        XCTAssertEqual(recommendations.first?.dimensionId, "architecture")
        XCTAssertEqual(recommendations.first?.priority, "Hohe Priorität")

        // Platform is second lowest
        XCTAssertEqual(recommendations[1].dimensionId, "platform")
        XCTAssertEqual(recommendations[1].priority, "Empfohlen")

        // Quality is highest
        XCTAssertEqual(recommendations.last?.dimensionId, "quality")
        XCTAssertEqual(recommendations.last?.priority, "Vertiefung")

        let size = renderInHost(recView)
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    func testPedagogicalRecommendationsWithEmptyScores() {
        let recView = PedagogicalRecommendationsView(dimensionScores: [:])
        XCTAssertTrue(recView.recommendations.isEmpty)
        let size = renderInHost(recView)
        XCTAssertGreaterThanOrEqual(size.width, 0)
    }

    // MARK: - AssessmentResultView Tests

    func testAssessmentResultViewDurationFormatting() {
        let recordShort = AssessmentRecord(
            catalogId: "cat-1",
            durationSeconds: 42.0,
            dimensionScores: ["architecture": 80.0],
            overallScore: 80.0,
            archetype: ArchetypeProfile.standardArchetypes[0],
            answers: []
        )
        let resultViewShort = AssessmentResultView(record: recordShort, onRestart: {})
        XCTAssertEqual(resultViewShort.formattedDuration, "42 Sek.")

        let recordLong = AssessmentRecord(
            catalogId: "cat-1",
            durationSeconds: 195.0, // 3 min 15 sec
            dimensionScores: ["architecture": 80.0],
            overallScore: 80.0,
            archetype: ArchetypeProfile.standardArchetypes[0],
            answers: []
        )
        let resultViewLong = AssessmentResultView(record: recordLong, onRestart: {})
        XCTAssertEqual(resultViewLong.formattedDuration, "3 Min. 15 Sek.")
    }

    func testAssessmentResultViewDimensionsFallback() {
        let record = AssessmentRecord(
            catalogId: "cat-1",
            durationSeconds: 120.0,
            dimensionScores: [
                "architecture": 85.0,
                "platform": 90.0,
                "quality": 78.0,
                "agile": 82.0
            ],
            overallScore: 83.75,
            archetype: ArchetypeProfile.standardArchetypes[1],
            answers: []
        )

        // Without catalog (nil)
        let resultViewWithoutCatalog = AssessmentResultView(record: record, catalog: nil, onRestart: {})
        XCTAssertEqual(resultViewWithoutCatalog.dimensionsToDisplay.count, 4)

        // With mock catalog
        let customDim = AssessmentDimension(
            id: "custom",
            name: "Custom Dimension",
            summary: "Custom",
            iconName: "star",
            targetWeight: 1.0
        )
        let customCatalog = AssessmentCatalog(
            catalogId: "custom-cat",
            version: "1.0.0",
            title: "Custom Catalog",
            subtitle: "Custom Subtitle",
            description: "Catalog",
            dimensions: [customDim],
            questions: [],
            archetypes: []
        )
        let resultViewWithCatalog = AssessmentResultView(record: record, catalog: customCatalog, onRestart: {})
        XCTAssertEqual(resultViewWithCatalog.dimensionsToDisplay.count, 1)
        XCTAssertEqual(resultViewWithCatalog.dimensionsToDisplay.first?.id, "custom")
    }

    func testAssessmentResultViewRestartActionAndHosting() {
        var restartTriggered = false
        let record = AssessmentRecord(
            catalogId: "cat-1",
            durationSeconds: 65.0,
            dimensionScores: ["architecture": 80.0],
            overallScore: 80.0,
            archetype: ArchetypeProfile.standardArchetypes[2],
            answers: []
        )
        let resultView = AssessmentResultView(
            record: record,
            onRestart: {
                restartTriggered = true
            }
        )

        resultView.onRestart()
        XCTAssertTrue(restartTriggered, "onRestart callback must be triggered")

        let size = renderInHost(resultView)
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }
}
