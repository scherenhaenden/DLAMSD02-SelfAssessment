import Foundation

/// Records the user's specific response to an assessment item.
public struct AssessmentAnswer: Identifiable, Codable, Sendable, Hashable {
    public var id: String { questionId }
    public let questionId: String
    public let dimensionId: String
    public let questionType: QuestionType

    // Payload depending on questionType
    public let selectedOptionIds: [String]?
    public let sliderValue: Double?
    public let textInput: String?

    /// Normalized score awarded for this response (strictly clamped to 0.0 ... 100.0).
    public let normalizedScore: Double

    public init(
        questionId: String,
        dimensionId: String,
        questionType: QuestionType,
        selectedOptionIds: [String]? = nil,
        sliderValue: Double? = nil,
        textInput: String? = nil,
        normalizedScore: Double
    ) {
        self.questionId = questionId
        self.dimensionId = dimensionId
        self.questionType = questionType
        self.selectedOptionIds = selectedOptionIds
        self.sliderValue = sliderValue
        self.textInput = textInput
        self.normalizedScore = min(100.0, max(0.0, normalizedScore))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.questionId = try container.decode(String.self, forKey: .questionId)
        self.dimensionId = try container.decode(String.self, forKey: .dimensionId)
        self.questionType = try container.decode(QuestionType.self, forKey: .questionType)
        self.selectedOptionIds = try container.decodeIfPresent([String].self, forKey: .selectedOptionIds)
        self.sliderValue = try container.decodeIfPresent(Double.self, forKey: .sliderValue)
        self.textInput = try container.decodeIfPresent(String.self, forKey: .textInput)

        // Strict defensive decoding: Clamp raw decoded score to [0.0 ... 100.0]
        let rawScore = try container.decode(Double.self, forKey: .normalizedScore)
        self.normalizedScore = min(100.0, max(0.0, rawScore))
    }
}

/// The immutable record representing a fully completed self-assessment session.
public struct AssessmentRecord: Identifiable, Codable, Sendable, Comparable {
    public let id: UUID
    public let catalogId: String
    public let completedAt: Date
    public let durationSeconds: Double

    /// Normalized score per dimension (0.0 to 100.0).
    public let dimensionScores: [String: Double]

    /// Global aggregated score (0.0 to 100.0).
    public let overallScore: Double

    /// Evaluated archetype profile.
    public let archetype: ArchetypeProfile

    /// All individual answers recorded during the assessment.
    public let answers: [AssessmentAnswer]

    public init(
        id: UUID = UUID(),
        catalogId: String,
        completedAt: Date = Date(),
        durationSeconds: Double,
        dimensionScores: [String: Double],
        overallScore: Double,
        archetype: ArchetypeProfile,
        answers: [AssessmentAnswer]
    ) {
        self.id = id
        self.catalogId = catalogId
        self.completedAt = completedAt
        self.durationSeconds = max(0.0, durationSeconds)
        self.dimensionScores = dimensionScores
        self.overallScore = min(100.0, max(0.0, overallScore))
        self.archetype = archetype
        self.answers = answers
    }

    /// Strict canonical 4-tier comparison satisfying mathematical strict weak ordering and transitivity:
    /// Tier 1: Overall Score (ascending)
    /// Tier 2: Completion timestamp (ascending / older first)
    /// Tier 3: Duration (descending / faster duration is superior)
    /// Tier 4: Canonical UUID tie-breaker (lexicographical)
    public static func < (lhs: AssessmentRecord, rhs: AssessmentRecord) -> Bool {
        if lhs.overallScore != rhs.overallScore {
            return lhs.overallScore < rhs.overallScore
        }
        if lhs.completedAt != rhs.completedAt {
            return lhs.completedAt < rhs.completedAt
        }
        if lhs.durationSeconds != rhs.durationSeconds {
            return lhs.durationSeconds > rhs.durationSeconds
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
