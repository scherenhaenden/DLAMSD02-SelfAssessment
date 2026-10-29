import Foundation

/// A self-contained evaluation catalog containing dimensions, questions and scoring archetypes.
public struct AssessmentCatalog: Identifiable, Codable, Sendable {
    public var id: String { catalogId }
    public let catalogId: String
    public let version: String
    public let title: String
    public let subtitle: String
    public let description: String
    public let dimensions: [AssessmentDimension]
    public let questions: [AssessmentQuestion]
    public let archetypes: [ArchetypeProfile]

    public init(
        catalogId: String,
        version: String,
        title: String,
        subtitle: String,
        description: String,
        dimensions: [AssessmentDimension],
        questions: [AssessmentQuestion],
        archetypes: [ArchetypeProfile]
    ) {
        self.catalogId = catalogId
        self.version = version
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.dimensions = dimensions
        self.questions = questions
        self.archetypes = archetypes
    }

    /// Performs comprehensive catalog integrity verification.
    public func validateIntegrity() throws {
        guard !catalogId.isEmpty else {
            throw AssessmentCatalogError.missingCatalogId
        }
        guard !dimensions.isEmpty else {
            throw AssessmentCatalogError.emptyDimensions
        }
        guard !questions.isEmpty else {
            throw AssessmentCatalogError.emptyQuestions
        }

        let dimensionIds = Set(dimensions.map(\.id))
        guard dimensionIds.count == dimensions.count else {
            throw AssessmentCatalogError.duplicateDimensionIds
        }

        for question in questions {
            try question.validateInvariants()
            guard dimensionIds.contains(question.dimensionId) else {
                throw AssessmentCatalogError.unmappedDimension(questionId: question.id, dimensionId: question.dimensionId)
            }
        }

        guard !archetypes.isEmpty else {
            throw AssessmentCatalogError.emptyArchetypes
        }
    }
}

public enum AssessmentCatalogError: LocalizedError, Equatable {
    case missingCatalogId
    case emptyDimensions
    case emptyQuestions
    case duplicateDimensionIds
    case unmappedDimension(questionId: String, dimensionId: String)
    case emptyArchetypes

    public var errorDescription: String? {
        switch self {
        case .missingCatalogId:
            return "Assessment catalog identifier cannot be empty."
        case .emptyDimensions:
            return "Assessment catalog must define at least one evaluation dimension."
        case .emptyQuestions:
            return "Assessment catalog contains no questions."
        case .duplicateDimensionIds:
            return "Assessment catalog contains duplicate dimension identifiers."
        case .unmappedDimension(let qid, let dim):
            return "Question '\(qid)' references undefined dimension '\(dim)'."
        case .emptyArchetypes:
            return "Assessment catalog must define at least one diagnostic archetype."
        }
    }
}
