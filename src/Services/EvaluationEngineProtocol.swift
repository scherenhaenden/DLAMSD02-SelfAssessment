import Foundation

/// Defines contract for evaluating user responses and synthesizing diagnostic profiles.
public protocol EvaluationEngineProtocol: Sendable {
    func evaluate(
        answers: [AssessmentAnswer],
        catalog: AssessmentCatalog,
        durationSeconds: Double
    ) throws -> AssessmentRecord

    func scoreQuestion(
        question: AssessmentQuestion,
        selectedOptionIds: [String]?,
        sliderValue: Double?,
        textInput: String?
    ) -> Double
}

/// Core psychometric and multi-dimensional scoring engine.
public final class AssessmentEvaluationEngine: EvaluationEngineProtocol {

    public init() {}

    public func scoreQuestion(
        question: AssessmentQuestion,
        selectedOptionIds: [String]?,
        sliderValue: Double?,
        textInput: String?
    ) -> Double {
        switch question.type {
        case .singleChoice:
            guard let selectedId = selectedOptionIds?.first,
                  let option = question.options?.first(where: { $0.id == selectedId }) else {
                return 0.0
            }
            return min(100.0, max(0.0, option.scoreWeight))

        case .multipleChoice:
            guard let selectedIds = selectedOptionIds, !selectedIds.isEmpty,
                  let options = question.options else {
                return 0.0
            }
            let matchingOptions = options.filter { selectedIds.contains($0.id) }
            let totalWeight = matchingOptions.reduce(0.0) { $0 + $1.scoreWeight }
            return min(100.0, max(0.0, totalWeight))

        case .likertSlider:
            let minVal = question.sliderMin ?? 1.0
            let maxVal = question.sliderMax ?? 5.0
            let currentVal = sliderValue ?? question.sliderDefault ?? ((minVal + maxVal) / 2.0)
            guard maxVal > minVal else { return 50.0 }
            let normalized = (currentVal - minVal) / (maxVal - minVal) * 100.0
            return min(100.0, max(0.0, normalized))

        case .shortText:
            let text = textInput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let minLen = question.minCharacters ?? 15
            let maxLen = question.maxCharacters ?? 350
            guard text.count >= minLen else {
                // If text is below minimum required characters, partial score proportional to length
                let ratio = Double(text.count) / Double(minLen)
                return min(40.0, max(0.0, ratio * 40.0))
            }

            // Base score for satisfying required length
            var score = 70.0

            // Bonus for technical domain relevance (keywords)
            let lowercased = text.lowercased()
            let keywords = [
                "swift", "swiftui", "protocol", "protokoll", "mvvm", "viewmodel", "combine",
                "test", "xctest", "coverage", "llvm", "invariant", "schichten", "architektur",
                "entkopplung", "git", "commit", "sprint", "refactoring", "boundary", "rollback"
            ]
            let matchedKeywords = keywords.filter { lowercased.contains($0) }
            let keywordBonus = Double(min(3, matchedKeywords.count)) * 10.0
            score += keywordBonus

            // Upper limit check
            if text.count > maxLen {
                score -= 10.0 // Slight penalty for exceeding maximum limit
            }

            return min(100.0, max(0.0, score))
        }
    }

    public func evaluate(
        answers: [AssessmentAnswer],
        catalog: AssessmentCatalog,
        durationSeconds: Double
    ) throws -> AssessmentRecord {
        guard !answers.isEmpty else {
            throw EvaluationEngineError.emptyAnswers
        }

        // Group answers by dimension
        var dimensionScores: [String: Double] = [:]
        var dimensionTotals: [String: (sum: Double, count: Int)] = [:]

        for dimension in catalog.dimensions {
            dimensionTotals[dimension.id] = (0.0, 0)
        }

        for answer in answers {
            var current = dimensionTotals[answer.dimensionId] ?? (0.0, 0)
            current.sum += answer.normalizedScore
            current.count += 1
            dimensionTotals[answer.dimensionId] = current
        }

        for dimension in catalog.dimensions {
            let total = dimensionTotals[dimension.id] ?? (0.0, 0)
            if total.count > 0 {
                dimensionScores[dimension.id] = total.sum / Double(total.count)
            } else {
                dimensionScores[dimension.id] = 0.0
            }
        }

        // Global aggregated overall score
        let overallScore: Double
        if !catalog.dimensions.isEmpty {
            let totalSum = catalog.dimensions.reduce(0.0) { sum, dim in
                sum + (dimensionScores[dim.id] ?? 0.0)
            }
            overallScore = totalSum / Double(catalog.dimensions.count)
        } else {
            overallScore = 0.0
        }

        // Select dominant archetype
        let dominantArchetype = selectDominantArchetype(
            dimensionScores: dimensionScores,
            archetypes: catalog.archetypes
        )

        return AssessmentRecord(
            catalogId: catalog.catalogId,
            completedAt: Date(),
            durationSeconds: durationSeconds,
            dimensionScores: dimensionScores,
            overallScore: overallScore,
            archetype: dominantArchetype,
            answers: answers
        )
    }

    private func selectDominantArchetype(
        dimensionScores: [String: Double],
        archetypes: [ArchetypeProfile]
    ) -> ArchetypeProfile {
        // Find dimension with highest score
        let sortedDimensions = dimensionScores.sorted { $0.value > $1.value }
        if let topDimension = sortedDimensions.first {
            if let matchingArchetype = archetypes.first(where: { $0.dominantDimensionId == topDimension.key }) {
                return matchingArchetype
            }
        }
        return archetypes.first ?? ArchetypeProfile.standardArchetypes[0]
    }
}

public enum EvaluationEngineError: LocalizedError, Equatable {
    case emptyAnswers

    public var errorDescription: String? {
        switch self {
        case .emptyAnswers:
            return "Cannot evaluate assessment with empty answers list."
        }
    }
}
