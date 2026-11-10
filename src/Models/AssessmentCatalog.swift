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

        // Validate semantic version format (e.g., 1.0.0) with safe integer components (< 1,000,000)
        let versionComponents = version.split(separator: ".", omittingEmptySubsequences: false)
        guard versionComponents.count >= 1 && versionComponents.count <= 3 else {
            throw AssessmentCatalogError.invalidVersionFormat(version: version)
        }
        for component in versionComponents {
            guard let intVal = Int(component), intVal >= 0, intVal < 1_000_000 else {
                throw AssessmentCatalogError.invalidVersionFormat(version: version)
            }
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

    /// Bumps the major SemVer component when structural questions are added or removed.
    /// Modifying the item battery alters the underlying measurement instrument,
    /// so historical delta comparisons against the prior version must be invalidated.
    private func bumpedMajorVersion() -> String {
        let components = version.split(separator: ".")
        if let majorStr = components.first, let major = Int(majorStr), major < 1_000_000 {
            return "\(major + 1).0.0"
        }
        return "2.0.0"
    }

    /// Returns a new catalog instance with an added question, ensuring catalog integrity.
    public func addingQuestion(_ question: AssessmentQuestion) throws -> AssessmentCatalog {
        guard !questions.contains(where: { $0.id == question.id }) else {
            throw AssessmentCatalogError.duplicateQuestionId(questionId: question.id)
        }
        var updated = questions
        updated.append(question)
        let newCatalog = AssessmentCatalog(
            catalogId: self.catalogId,
            version: bumpedMajorVersion(),
            title: self.title,
            subtitle: self.subtitle,
            description: self.description,
            dimensions: self.dimensions,
            questions: updated,
            archetypes: self.archetypes
        )
        try newCatalog.validateIntegrity()
        return newCatalog
    }

    /// Returns a new catalog instance with a specified question removed, ensuring catalog integrity.
    public func removingQuestion(id: String) throws -> AssessmentCatalog {
        let updated = questions.filter { $0.id != id }
        let newCatalog = AssessmentCatalog(
            catalogId: self.catalogId,
            version: bumpedMajorVersion(),
            title: self.title,
            subtitle: self.subtitle,
            description: self.description,
            dimensions: self.dimensions,
            questions: updated,
            archetypes: self.archetypes
        )
        try newCatalog.validateIntegrity()
        return newCatalog
    }
}

public enum AssessmentCatalogError: LocalizedError, Equatable {
    case missingCatalogId
    case invalidVersionFormat(version: String)
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
        case .invalidVersionFormat(let versionStr):
            return "Assessment catalog version '\(versionStr)' is invalid. Expected semantic version format X.Y.Z with safe integer components."
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
