import Foundation

/// Supported question interaction paradigms for self-assessment.
public enum QuestionType: String, Codable, Sendable, CaseIterable {
    /// Single choice selection (e.g. decision scenarios, 1 of N).
    case singleChoice = "single_choice"
    /// Multiple choice selection (e.g. toolset or competency checklist).
    case multipleChoice = "multiple_choice"
    /// Continuous or discrete Likert rating slider (e.g. 1 to 5 agreement).
    case likertSlider = "likert_slider"
    /// Validated short text input for structured self-reflection.
    case shortText = "short_text"
}

/// A selectable option for single or multiple choice questions.
public struct ChoiceOption: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let detail: String?
    public let scoreWeight: Double

    public init(
        id: String,
        title: String,
        detail: String? = nil,
        scoreWeight: Double
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.scoreWeight = scoreWeight
    }
}
