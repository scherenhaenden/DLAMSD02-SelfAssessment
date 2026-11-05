import Foundation
import Combine

/// Strongly-typed user response payloads for SwiftUI input components.
public enum AnswerPayload: Equatable, Sendable {
    case singleChoice(selectedOptionId: String)
    case multipleChoice(selectedOptionIds: [String])
    case steppedSlider(value: Double)
    case shortText(text: String)
}

/// State machine representation of an active self-assessment session.
public enum AssessmentSessionState: Equatable {
    case idle
    case loading
    case inProgress
    case completed(AssessmentRecord)
    case error(String)
}

/// Protocol defining the contract for managing sequential assessment flow, answers, and evaluation.
public protocol AssessmentViewModelProtocol: ObservableObject {
    var state: AssessmentSessionState { get }
    var catalog: AssessmentCatalog? { get }
    var currentQuestionIndex: Int { get }
    var totalQuestions: Int { get }
    var currentQuestion: AssessmentQuestion? { get }
    var currentDimension: AssessmentDimension? { get }
    var progress: Double { get }
    var answers: [String: AnswerPayload] { get }
    var hapticService: (any HapticFeedbackServiceProtocol)? { get set }
    var hasExplicitHapticService: Bool { get }
    var historyStore: (any HistoryStoreProtocol)? { get }

    // Navigation Affordances
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    var isLastQuestion: Bool { get }
    var isCurrentAnswerValid: Bool { get }

    // Action Methods
    func loadCatalog()
    func recordSingleChoice(questionId: String, selectedOptionId: String)
    func toggleMultipleChoice(questionId: String, optionId: String)
    func recordSliderValue(questionId: String, value: Double)
    func recordShortText(questionId: String, text: String)
    func advance()
    func goBack()
    func submitAssessment()
    func reset()
}
