import Foundation

/// A self-assessment question item with polymorphic interaction semantics.
public struct AssessmentQuestion: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let dimensionId: String
    public let type: QuestionType
    public let title: String
    public let prompt: String
    public let guidance: String?

    // Single / Multiple choice properties
    public let options: [ChoiceOption]?
    public let minSelectCount: Int?
    public let maxSelectCount: Int?

    // Likert slider properties
    public let sliderMin: Double?
    public let sliderMax: Double?
    public let sliderStep: Double?
    public let sliderMinLabel: String?
    public let sliderMaxLabel: String?
    public let sliderDefault: Double?

    // Short text properties
    public let textPlaceholder: String?
    public let minCharacters: Int?
    public let maxCharacters: Int?

    public init(
        id: String,
        dimensionId: String,
        type: QuestionType,
        title: String,
        prompt: String,
        guidance: String? = nil,
        options: [ChoiceOption]? = nil,
        minSelectCount: Int? = nil,
        maxSelectCount: Int? = nil,
        sliderMin: Double? = nil,
        sliderMax: Double? = nil,
        sliderStep: Double? = nil,
        sliderMinLabel: String? = nil,
        sliderMaxLabel: String? = nil,
        sliderDefault: Double? = nil,
        textPlaceholder: String? = nil,
        minCharacters: Int? = nil,
        maxCharacters: Int? = nil
    ) {
        self.id = id
        self.dimensionId = dimensionId
        self.type = type
        self.title = title
        self.prompt = prompt
        self.guidance = guidance
        self.options = options
        self.minSelectCount = minSelectCount
        self.maxSelectCount = maxSelectCount
        self.sliderMin = sliderMin
        self.sliderMax = sliderMax
        self.sliderStep = sliderStep
        self.sliderMinLabel = sliderMinLabel
        self.sliderMaxLabel = sliderMaxLabel
        self.sliderDefault = sliderDefault
        self.textPlaceholder = textPlaceholder
        self.minCharacters = minCharacters
        self.maxCharacters = maxCharacters
    }

    /// Verifies strict domain invariants. Throws a descriptive ValidationError if malformed.
    public func validateInvariants() throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AssessmentValidationError.emptyIdentifier
        }
        guard !dimensionId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AssessmentValidationError.emptyDimensionIdentifier(questionId: id)
        }
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AssessmentValidationError.emptyPrompt(questionId: id)
        }

        switch type {
        case .singleChoice, .multipleChoice:
            guard let options = options, options.count >= 2 else {
                throw AssessmentValidationError.insufficientOptions(questionId: id, count: options?.count ?? 0)
            }
            let uniqueOptionIds = Set(options.map(\.id))
            guard uniqueOptionIds.count == options.count else {
                throw AssessmentValidationError.duplicateOptionIdentifiers(questionId: id)
            }

        case .likertSlider:
            let minVal = sliderMin ?? 1.0
            let maxVal = sliderMax ?? 5.0
            guard minVal < maxVal else {
                throw AssessmentValidationError.invalidSliderRange(questionId: id, min: minVal, max: maxVal)
            }

        case .shortText:
            let minLen = minCharacters ?? 10
            let maxLen = maxCharacters ?? 500
            guard minLen > 0, minLen <= maxLen else {
                throw AssessmentValidationError.invalidTextBounds(questionId: id, min: minLen, max: maxLen)
            }
        }
    }
}

/// Errors raised when domain invariant constraints are violated.
public enum AssessmentValidationError: LocalizedError, Equatable {
    case emptyIdentifier
    case emptyDimensionIdentifier(questionId: String)
    case emptyPrompt(questionId: String)
    case insufficientOptions(questionId: String, count: Int)
    case duplicateOptionIdentifiers(questionId: String)
    case invalidSliderRange(questionId: String, min: Double, max: Double)
    case invalidTextBounds(questionId: String, min: Int, max: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyIdentifier:
            return "Assessment question identifier cannot be empty."
        case .emptyDimensionIdentifier(let qid):
            return "Assessment question '\(qid)' must be assigned to a non-empty dimension."
        case .emptyPrompt(let qid):
            return "Assessment question '\(qid)' prompt cannot be empty."
        case .insufficientOptions(let qid, let count):
            return "Choice question '\(qid)' requires at least 2 options, found \(count)."
        case .duplicateOptionIdentifiers(let qid):
            return "Choice question '\(qid)' contains duplicate option identifiers."
        case .invalidSliderRange(let qid, let min, let max):
            return "Slider question '\(qid)' has invalid range (min: \(min), max: \(max))."
        case .invalidTextBounds(let qid, let min, let max):
            return "Short text question '\(qid)' has invalid character length constraints (min: \(min), max: \(max))."
        }
    }
}
