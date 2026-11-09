import Foundation
import Combine

/// Production implementation of `AssessmentViewModelProtocol` managing the assessment state machine,
/// sequential navigation, answer storage, and evaluation coordination without static singletons.
public final class AssessmentViewModel: AssessmentViewModelProtocol {
    @Published public private(set) var state: AssessmentSessionState = .idle
    @Published public private(set) var catalog: AssessmentCatalog? = nil
    @Published public private(set) var currentQuestionIndex: Int = 0
    @Published public private(set) var answers: [String: AnswerPayload] = [:]
    @Published public private(set) var persistenceError: String? = nil

    private let catalogLoader: CatalogLoaderProtocol
    private let evaluationEngine: EvaluationEngineProtocol
    public var hapticService: (any HapticFeedbackServiceProtocol)?
    public internal(set) var hasExplicitHapticService: Bool
    public var historyStore: (any HistoryStoreProtocol)?
    public var catalogStore: (any SandboxCatalogStoreProtocol)?
    private var sessionStartTime: Date?

    /// Designated initializer for explicit dependency injection.
    /// Marks `hasExplicitHapticService = true` to preserve caller-provided configuration across view lifecycles.
    public init(
        catalogLoader: CatalogLoaderProtocol = CatalogLoader(),
        evaluationEngine: EvaluationEngineProtocol = EvaluationEngine(),
        hapticService: (any HapticFeedbackServiceProtocol)?,
        historyStore: (any HistoryStoreProtocol)? = nil,
        catalogStore: (any SandboxCatalogStoreProtocol)? = nil
    ) {
        self.catalogLoader = catalogLoader
        self.evaluationEngine = evaluationEngine
        self.hapticService = hapticService
        self.hasExplicitHapticService = true
        self.historyStore = historyStore
        self.catalogStore = catalogStore
    }

    /// Convenience initializer using default system haptic feedback service.
    /// Marks `hasExplicitHapticService = false` allowing SwiftUI Environment injection to customize feedback.
    public convenience init(
        catalogLoader: CatalogLoaderProtocol = CatalogLoader(),
        evaluationEngine: EvaluationEngineProtocol = EvaluationEngine(),
        historyStore: (any HistoryStoreProtocol)? = nil,
        catalogStore: (any SandboxCatalogStoreProtocol)? = nil
    ) {
        self.init(
            catalogLoader: catalogLoader,
            evaluationEngine: evaluationEngine,
            hapticService: SystemHapticFeedbackService(),
            historyStore: historyStore,
            catalogStore: catalogStore
        )
        self.hasExplicitHapticService = false
    }

    // MARK: - Computed Properties

    public var totalQuestions: Int {
        catalog?.questions.count ?? 0
    }

    public var currentQuestion: AssessmentQuestion? {
        guard let catalog = catalog,
              currentQuestionIndex >= 0 && currentQuestionIndex < catalog.questions.count else {
            return nil
        }
        return catalog.questions[currentQuestionIndex]
    }

    public var currentDimension: AssessmentDimension? {
        guard let question = currentQuestion, let catalog = catalog else {
            return nil
        }
        return catalog.dimensions.first(where: { $0.id == question.dimensionId })
    }

    public var progress: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(currentQuestionIndex + 1) / Double(totalQuestions)
    }

    public var canGoBack: Bool {
        currentQuestionIndex > 0
    }

    public var canGoForward: Bool {
        isCurrentAnswerValid && currentQuestionIndex < totalQuestions - 1
    }

    public var isLastQuestion: Bool {
        totalQuestions > 0 && currentQuestionIndex == totalQuestions - 1
    }

    public var isCurrentAnswerValid: Bool {
        guard let question = currentQuestion, let payload = answers[question.id] else {
            return false
        }

        switch (question.type, payload) {
        case (.singleChoice, .singleChoice(let selectedOptionId)):
            guard let options = question.options,
                  options.contains(where: { $0.id == selectedOptionId }) else {
                return false
            }
            return true

        case (.multipleChoice, .multipleChoice(let selectedOptionIds)):
            guard let options = question.options, !selectedOptionIds.isEmpty else {
                return false
            }
            guard Set(selectedOptionIds).count == selectedOptionIds.count else {
                return false
            }
            let validOptionIds = Set(options.map(\.id))
            guard selectedOptionIds.allSatisfy({ validOptionIds.contains($0) }) else {
                return false
            }
            let minSelect = question.minSelectCount ?? 1
            let maxSelect = question.maxSelectCount ?? options.count
            return selectedOptionIds.count >= minSelect && selectedOptionIds.count <= maxSelect

        case (.likertSlider, .steppedSlider(let value)):
            let minVal = question.sliderMin ?? 1.0
            let maxVal = question.sliderMax ?? 5.0
            guard value >= minVal && value <= maxVal else {
                return false
            }
            if let step = question.sliderStep, step > 0.0 {
                let delta = value - minVal
                let remainder = delta.truncatingRemainder(dividingBy: step)
                let tolerance = 0.0001
                return abs(remainder) < tolerance || abs(remainder - step) < tolerance
            }
            return true

        case (.shortText, .shortText(let text)):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let minLen = question.minCharacters ?? 15
            let maxLen = question.maxCharacters ?? 350
            return trimmed.count >= minLen && trimmed.count <= maxLen

        default:
            return false
        }
    }

    // MARK: - Action Methods

    public func loadCatalog() {
        state = .loading
        hapticService?.prepare()
        do {
            let loadedCatalog: AssessmentCatalog
            if let store = catalogStore {
                loadedCatalog = try store.loadActiveCatalog()
            } else {
                loadedCatalog = try catalogLoader.loadBundledCatalog()
            }
            self.catalog = loadedCatalog
            self.currentQuestionIndex = 0
            self.answers.removeAll()
            self.sessionStartTime = Date()
            self.state = .inProgress
            ensureDefaultAnswerIfNeeded()
        } catch {
            self.state = .error(error.localizedDescription)
            hapticService?.triggerNotification(.error)
        }
    }

    public func recordSingleChoice(questionId: String, selectedOptionId: String) {
        answers[questionId] = .singleChoice(selectedOptionId: selectedOptionId)
        hapticService?.triggerSelection()
    }

    public func toggleMultipleChoice(questionId: String, optionId: String) {
        var current: [String] = []
        if case .multipleChoice(let ids) = answers[questionId] {
            current = ids
        }
        if let existingIndex = current.firstIndex(of: optionId) {
            current.remove(at: existingIndex)
        } else {
            if let question = catalog?.questions.first(where: { $0.id == questionId }),
               let maxCount = question.maxSelectCount {
                if current.count < maxCount {
                    current.append(optionId)
                }
            } else {
                current.append(optionId)
            }
        }

        if current.isEmpty {
            answers.removeValue(forKey: questionId)
        } else {
            answers[questionId] = .multipleChoice(selectedOptionIds: current)
        }
        hapticService?.triggerSelection()
    }

    public func recordSliderValue(questionId: String, value: Double) {
        answers[questionId] = .steppedSlider(value: value)
        hapticService?.triggerSelection()
    }

    public func recordShortText(questionId: String, text: String) {
        answers[questionId] = .shortText(text: text)
    }

    public func advance() {
        guard canGoForward else { return }
        currentQuestionIndex += 1
        ensureDefaultAnswerIfNeeded()
        hapticService?.triggerImpact(.light)
    }

    public func goBack() {
        guard canGoBack else { return }
        currentQuestionIndex -= 1
        ensureDefaultAnswerIfNeeded()
        hapticService?.triggerImpact(.light)
    }

    private func ensureDefaultAnswerIfNeeded() {
        guard let question = currentQuestion else { return }
        if question.type == .likertSlider && answers[question.id] == nil {
            let defaultVal = question.sliderDefault ?? question.sliderMin ?? 1.0
            answers[question.id] = .steppedSlider(value: defaultVal)
        }
    }

    public func submitAssessment() {
        guard let catalog = catalog else {
            state = .error("No catalog loaded to evaluate.")
            return
        }
        guard isCurrentAnswerValid else {
            state = .error("Current question must have a valid answer before submission.")
            return
        }

        var assessmentAnswers: [AssessmentAnswer] = []
        for question in catalog.questions {
            guard let payload = answers[question.id] else {
                state = .error("Assessment incomplete: missing answer for question '\(question.id)'.")
                return
            }

            let selectedOptionIds: [String]?
            let sliderValue: Double?
            let textInput: String?

            switch payload {
            case .singleChoice(let optId):
                selectedOptionIds = [optId]
                sliderValue = nil
                textInput = nil
            case .multipleChoice(let optIds):
                selectedOptionIds = optIds
                sliderValue = nil
                textInput = nil
            case .steppedSlider(let val):
                selectedOptionIds = nil
                sliderValue = val
                textInput = nil
            case .shortText(let txt):
                selectedOptionIds = nil
                sliderValue = nil
                textInput = txt
            }

            let answer = AssessmentAnswer(
                questionId: question.id,
                dimensionId: question.dimensionId,
                questionType: question.type,
                selectedOptionIds: selectedOptionIds,
                sliderValue: sliderValue,
                textInput: textInput
            )
            assessmentAnswers.append(answer)
        }

        let duration = max(1.0, Date().timeIntervalSince(sessionStartTime ?? Date()))
        do {
            let record = try evaluationEngine.evaluate(
                answers: assessmentAnswers,
                catalog: catalog,
                durationSeconds: duration
            )
            if let store = historyStore {
                do {
                    try store.save(record: record)
                    self.persistenceError = nil
                } catch {
                    self.persistenceError = error.localizedDescription
                }
            } else {
                self.persistenceError = nil
            }
            state = .completed(record)
            if persistenceError == nil {
                hapticService?.triggerNotification(.success)
            } else {
                hapticService?.triggerNotification(.warning)
            }
        } catch {
            state = .error(error.localizedDescription)
            hapticService?.triggerNotification(.error)
        }
    }

    @discardableResult
    public func retryPersistence() -> Bool {
        guard case .completed(let record) = state, let store = historyStore else {
            return false
        }
        do {
            try store.save(record: record)
            self.persistenceError = nil
            hapticService?.triggerNotification(.success)
            return true
        } catch {
            self.persistenceError = error.localizedDescription
            hapticService?.triggerNotification(.error)
            return false
        }
    }

    public func reset() {
        state = .idle
        catalog = nil
        currentQuestionIndex = 0
        answers.removeAll()
        sessionStartTime = nil
        persistenceError = nil
        hapticService?.triggerImpact(.medium)
    }
}
