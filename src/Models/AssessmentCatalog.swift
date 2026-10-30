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
        guard !catalogId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AssessmentCatalogError.missingCatalogId
        }
        guard !dimensions.isEmpty else {
            throw AssessmentCatalogError.emptyDimensions
        }
        guard !questions.isEmpty else {
            throw AssessmentCatalogError.emptyQuestions
        }

        // Validate dimension uniqueness
        let dimensionIds = Set(dimensions.map(\.id))
        guard dimensionIds.count == dimensions.count else {
            throw AssessmentCatalogError.duplicateDimensionIds
        }

        // Validate question uniqueness and valid dimension mapping
        var seenQuestionIds = Set<String>()
        for question in questions {
            guard !seenQuestionIds.contains(question.id) else {
                throw AssessmentCatalogError.duplicateQuestionId(questionId: question.id)
            }
            seenQuestionIds.insert(question.id)

            try question.validateInvariants()

            guard dimensionIds.contains(question.dimensionId) else {
                throw AssessmentCatalogError.unmappedDimension(questionId: question.id, dimensionId: question.dimensionId)
            }
        }

        // Validate archetypes
        guard !archetypes.isEmpty else {
            throw AssessmentCatalogError.emptyArchetypes
        }

        var seenArchetypeIds = Set<String>()
        for archetype in archetypes {
            guard !seenArchetypeIds.contains(archetype.id) else {
                throw AssessmentCatalogError.duplicateArchetypeId(archetypeId: archetype.id)
            }
            seenArchetypeIds.insert(archetype.id)

            guard dimensionIds.contains(archetype.dominantDimensionId) else {
                throw AssessmentCatalogError.unmappedArchetypeDimension(
                    archetypeId: archetype.id,
                    dimensionId: archetype.dominantDimensionId
                )
            }
        }

        // Validate bidirectional coverage: every dimension must have questions and an archetype
        let questionDimensionIds = Set(questions.map(\.dimensionId))
        for dimension in dimensions {
            guard questionDimensionIds.contains(dimension.id) else {
                throw AssessmentCatalogError.dimensionWithoutQuestions(dimensionId: dimension.id)
            }
        }

        let archetypeDimensionIds = Set(archetypes.map(\.dominantDimensionId))
        for dimension in dimensions {
            guard archetypeDimensionIds.contains(dimension.id) else {
                throw AssessmentCatalogError.dimensionWithoutArchetype(dimensionId: dimension.id)
            }
        }
    }
}

public enum AssessmentCatalogError: LocalizedError, Equatable {
    case missingCatalogId
    case emptyDimensions
    case emptyQuestions
    case duplicateDimensionIds
    case duplicateQuestionId(questionId: String)
    case unmappedDimension(questionId: String, dimensionId: String)
    case emptyArchetypes
    case duplicateArchetypeId(archetypeId: String)
    case unmappedArchetypeDimension(archetypeId: String, dimensionId: String)
    case dimensionWithoutQuestions(dimensionId: String)
    case dimensionWithoutArchetype(dimensionId: String)

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
        case .duplicateQuestionId(let qid):
            return "Assessment catalog contains duplicate question identifier '\(qid)'."
        case .unmappedDimension(let qid, let dim):
            return "Question '\(qid)' references undefined dimension '\(dim)'."
        case .emptyArchetypes:
            return "Assessment catalog must define at least one diagnostic archetype."
        case .duplicateArchetypeId(let aid):
            return "Assessment catalog contains duplicate archetype identifier '\(aid)'."
        case .unmappedArchetypeDimension(let aid, let dim):
            return "Archetype '\(aid)' references undefined dominant dimension '\(dim)'."
        case .dimensionWithoutQuestions(let dim):
            return "Evaluation dimension '\(dim)' has no associated questions in catalog."
        case .dimensionWithoutArchetype(let dim):
            return "Evaluation dimension '\(dim)' has no corresponding diagnostic archetype."
        }
    }
}
