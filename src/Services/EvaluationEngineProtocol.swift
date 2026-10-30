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

/// Core didactic scoring and multi-dimensional evaluation engine.
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
            let validSelectedOptions = options.filter { selectedIds.contains($0.id) }
            guard !validSelectedOptions.isEmpty else {
                return 0.0
            }

            // Verify min/max selection bounds if defined
            let minSelect = question.minSelectCount ?? 1
            let maxSelect = question.maxSelectCount ?? options.count
            if selectedIds.count < minSelect || selectedIds.count > maxSelect {
                return 0.0 // Selection violation
            }

            let totalWeight = validSelectedOptions.reduce(0.0) { $0 + $1.scoreWeight }
            return min(100.0, max(0.0, totalWeight))

        case .likertSlider:
            guard let currentVal = sliderValue ?? question.sliderDefault else {
                return 0.0
            }
            let minVal = question.sliderMin ?? 1.0
            let maxVal = question.sliderMax ?? 5.0
            guard maxVal > minVal else { return 50.0 }
            let clampedVal = min(maxVal, max(minVal, currentVal))
            let normalized = (clampedVal - minVal) / (maxVal - minVal) * 100.0
            return min(100.0, max(0.0, normalized))

        case .shortText:
            let text = textInput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let minLen = question.minCharacters ?? 15
            let maxLen = question.maxCharacters ?? 350

            guard text.count >= minLen else {
                // If text is below minimum required characters, partial score proportional to length (max 30)
                let ratio = Double(text.count) / Double(minLen)
                return min(30.0, max(0.0, ratio * 30.0))
            }

            // Exceeding maximum allowed characters invalidates or caps the score
            guard text.count <= maxLen else {
                return 40.0 // Length violation penalty
            }

            // Base score for satisfying required length
            var score = 60.0

            // Word-tokenized matching (exact words, no substring collisions)
            let lowercased = text.lowercased()
            let wordTokens = Set(lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })

            let domainKeywords: Set<String> = [
                "swift", "swiftui", "protocol", "protokoll", "mvvm", "viewmodel", "combine",
                "test", "xctest", "coverage", "llvm", "invariant", "schichten", "architektur",
                "entkopplung", "git", "commit", "sprint", "refactoring", "boundary", "rollback"
            ]

            let matchedCount = wordTokens.intersection(domainKeywords).count
            let keywordBonus = Double(min(4, matchedCount)) * 10.0
            score += keywordBonus

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

        // Map catalog questions by ID for fast, strict lookup
        let questionMap = Dictionary(uniqueKeysWithValues: catalog.questions.map { ($0.id, $0) })

        // Check for duplicates and validate answers against active catalog
        var seenQuestionIds = Set<String>()
        var verifiedAnswers: [AssessmentAnswer] = []

        for answer in answers {
            guard !seenQuestionIds.contains(answer.questionId) else {
                throw EvaluationEngineError.duplicateAnswer(questionId: answer.questionId)
            }
            seenQuestionIds.insert(answer.questionId)

            guard let question = questionMap[answer.questionId] else {
                throw EvaluationEngineError.unknownQuestion(questionId: answer.questionId)
            }

            guard question.dimensionId == answer.dimensionId else {
                throw EvaluationEngineError.mismatchedDimension(
                    questionId: answer.questionId,
                    expected: question.dimensionId,
                    actual: answer.dimensionId
                )
            }

            guard question.type == answer.questionType else {
                throw EvaluationEngineError.mismatchedType(
                    questionId: answer.questionId,
                    expected: question.type,
                    actual: answer.questionType
                )
            }

            // Recalculate score from raw input payload rather than blindly trusting answer.normalizedScore
            let derivedScore = scoreQuestion(
                question: question,
                selectedOptionIds: answer.selectedOptionIds,
                sliderValue: answer.sliderValue,
                textInput: answer.textInput
            )

            let verifiedAnswer = AssessmentAnswer(
                questionId: answer.questionId,
                dimensionId: answer.dimensionId,
                questionType: answer.questionType,
                selectedOptionIds: answer.selectedOptionIds,
                sliderValue: answer.sliderValue,
                textInput: answer.textInput,
                normalizedScore: derivedScore
            )
            verifiedAnswers.append(verifiedAnswer)
        }

        // Group answers by dimension
        var dimensionScores: [String: Double] = [:]
        var dimensionTotals: [String: (sum: Double, count: Int)] = [:]

        for dimension in catalog.dimensions {
            dimensionTotals[dimension.id] = (0.0, 0)
        }

        for answer in verifiedAnswers {
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

        // Select dominant archetype deterministically
        let dominantArchetype = selectDominantArchetype(
            dimensionScores: dimensionScores,
            dimensions: catalog.dimensions,
            archetypes: catalog.archetypes
        )

        return AssessmentRecord(
            catalogId: catalog.catalogId,
            completedAt: Date(),
            durationSeconds: durationSeconds,
            dimensionScores: dimensionScores,
            overallScore: overallScore,
            archetype: dominantArchetype,
            answers: verifiedAnswers
        )
    }

    /// Selects dominant archetype with 100% deterministic tie-breaking based on canonical catalog dimension ordering.
    public func selectDominantArchetype(
        dimensionScores: [String: Double],
        dimensions: [AssessmentDimension],
        archetypes: [ArchetypeProfile]
    ) -> ArchetypeProfile {
        // Find maximum score across dimensions
        var maxScore: Double = -1.0
        for dim in dimensions {
            let score = dimensionScores[dim.id] ?? 0.0
            if score > maxScore {
                maxScore = score
            }
        }

        // Tie-breaker: Iterate in exact canonical declaration order of dimensions
        for dim in dimensions {
            let score = dimensionScores[dim.id] ?? 0.0
            if abs(score - maxScore) < 0.0001 {
                if let matchingArchetype = archetypes.first(where: { $0.dominantDimensionId == dim.id }) {
                    return matchingArchetype
                }
            }
        }

        return archetypes.first ?? ArchetypeProfile.standardArchetypes[0]
    }
}

public enum EvaluationEngineError: LocalizedError, Equatable {
    case emptyAnswers
    case duplicateAnswer(questionId: String)
    case unknownQuestion(questionId: String)
    case mismatchedDimension(questionId: String, expected: String, actual: String)
    case mismatchedType(questionId: String, expected: QuestionType, actual: QuestionType)

    public var errorDescription: String? {
        switch self {
        case .emptyAnswers:
            return "Cannot evaluate assessment with empty answers list."
        case .duplicateAnswer(let qid):
            return "Assessment contains duplicate answer for question '\(qid)'."
        case .unknownQuestion(let qid):
            return "Assessment answer references question '\(qid)' which does not exist in active catalog."
        case .mismatchedDimension(let qid, let exp, let act):
            return "Answer for '\(qid)' declared dimension '\(act)' but catalog defines '\(exp)'."
        case .mismatchedType(let qid, let exp, let act):
            return "Answer for '\(qid)' declared type '\(act.rawValue)' but catalog defines '\(exp.rawValue)'."
        }
    }
}
