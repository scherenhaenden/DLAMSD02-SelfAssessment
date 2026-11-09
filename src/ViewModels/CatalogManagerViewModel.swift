import Foundation
import Combine

/// Manages state and operations for the in-app catalog authoring and sandbox persistence interface.
public final class CatalogManagerViewModel: ObservableObject {
    @Published public private(set) var currentCatalog: AssessmentCatalog?
    @Published public private(set) var questions: [AssessmentQuestion] = []
    @Published public private(set) var dimensions: [AssessmentDimension] = []
    @Published public private(set) var hasCustomCatalog: Bool = false
    @Published public private(set) var statusMessage: String?
    @Published public private(set) var errorMessage: String?

    @Published public var selectedDimensionFilter: String?
    @Published public var isAddQuestionSheetPresented: Bool = false
    @Published public var isImportSheetPresented: Bool = false
    @Published public var isExportSheetPresented: Bool = false
    @Published public var isResetConfirmPresented: Bool = false
    @Published public var questionToDelete: AssessmentQuestion?
    @Published public var importJSONText: String = ""

    // Form inputs for question creation
    @Published public var formQuestionId: String = ""
    @Published public var formDimensionId: String = ""
    @Published public var formType: QuestionType = .singleChoice
    @Published public var formTitle: String = ""
    @Published public var formPrompt: String = ""
    @Published public var formGuidance: String = ""

    // Choice options
    @Published public var formOption1Title: String = "Option A"
    @Published public var formOption1Score: Double = 60.0
    @Published public var formOption2Title: String = "Option B"
    @Published public var formOption2Score: Double = 90.0

    // Slider inputs
    @Published public var formSliderMin: Double = 1.0
    @Published public var formSliderMax: Double = 5.0
    @Published public var formSliderStep: Double = 1.0
    @Published public var formSliderMinLabel: String = "Grundlegend"
    @Published public var formSliderMaxLabel: String = "Expertenniveau"
    @Published public var formSliderDefault: Double = 3.0

    // Short text inputs
    @Published public var formMinCharacters: Int = 15
    @Published public var formMaxCharacters: Int = 350
    @Published public var formPlaceholder: String = "Erläutern Sie Ihre Praxis..."

    public let catalogStore: SandboxCatalogStoreProtocol
    public var hapticService: (any HapticFeedbackServiceProtocol)?

    public init(
        catalogStore: SandboxCatalogStoreProtocol = SandboxCatalogStore(),
        hapticService: (any HapticFeedbackServiceProtocol)? = SystemHapticFeedbackService()
    ) {
        self.catalogStore = catalogStore
        self.hapticService = hapticService
        loadCatalog()
    }

    public var filteredQuestions: [AssessmentQuestion] {
        guard let filter = selectedDimensionFilter, !filter.isEmpty else {
            return questions
        }
        return questions.filter { $0.dimensionId == filter }
    }

    public var totalQuestionsCount: Int {
        questions.count
    }

    // MARK: - Core Catalog Operations

    /// Revalidates the active dimension filter against the currently loaded dimensions,
    /// resetting it to nil if the dimension was removed (e.g., following a catalog reset or import).
    private func revalidateFilter() {
        guard let current = currentCatalog else { return }
        if let filter = selectedDimensionFilter, !current.dimensions.contains(where: { $0.id == filter }) {
            self.selectedDimensionFilter = nil
        }
    }

    public func clearMessages() {
        self.errorMessage = nil
        self.statusMessage = nil
    }

    public func loadCatalog() {
        errorMessage = nil
        do {
            let catalog = try catalogStore.loadActiveCatalog()
            self.currentCatalog = catalog
            self.questions = catalog.questions
            self.dimensions = catalog.dimensions
            self.hasCustomCatalog = catalogStore.hasCustomCatalog
            if formDimensionId.isEmpty, let firstDim = catalog.dimensions.first {
                self.formDimensionId = firstDim.id
            }
            revalidateFilter()
        } catch let error as SandboxCatalogError {
            self.errorMessage = error.errorDescription
            self.hasCustomCatalog = catalogStore.hasCustomCatalog
            // If rollback was triggered, reload restored state
            if case .corruptedRollbackTriggered = error {
                if let catalog = try? catalogStore.loadActiveCatalog() {
                    self.currentCatalog = catalog
                    self.questions = catalog.questions
                    self.dimensions = catalog.dimensions
                    revalidateFilter()
                }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    public func resetForm() {
        formQuestionId = "q_custom_\(Int(Date().timeIntervalSince1970))"
        formTitle = ""
        formPrompt = ""
        formGuidance = ""
        formType = .singleChoice
        if let firstDim = dimensions.first {
            formDimensionId = firstDim.id
        }
        formOption1Title = "Option A"
        formOption1Score = 60.0
        formOption2Title = "Option B"
        formOption2Score = 90.0
        formSliderMin = 1.0
        formSliderMax = 5.0
        formSliderStep = 1.0
        formSliderMinLabel = "Grundlegend"
        formSliderMaxLabel = "Expertenniveau"
        formSliderDefault = 3.0
        formMinCharacters = 15
        formMaxCharacters = 350
        formPlaceholder = "Erläutern Sie Ihre Praxis..."
    }

    public var isFormValid: Bool {
        let trimmedId = formQuestionId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = formTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = formPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty && !trimmedTitle.isEmpty && !trimmedPrompt.isEmpty else {
            return false
        }
        guard !formDimensionId.isEmpty && dimensions.contains(where: { $0.id == formDimensionId }) else {
            return false
        }
        guard !questions.contains(where: { $0.id == trimmedId }) else {
            return false
        }

        switch formType {
        case .singleChoice, .multipleChoice:
            let o1 = formOption1Title.trimmingCharacters(in: .whitespacesAndNewlines)
            let o2 = formOption2Title.trimmingCharacters(in: .whitespacesAndNewlines)
            return !o1.isEmpty && !o2.isEmpty && o1 != o2
        case .likertSlider:
            return formSliderMin < formSliderMax && formSliderStep > 0
        case .shortText:
            return formMinCharacters >= 5 && formMaxCharacters > formMinCharacters
        }
    }

    @discardableResult
    public func saveNewQuestion() -> Bool {
        guard isFormValid, let active = currentCatalog else {
            errorMessage = "Bitte überprüfen Sie die Pflichtfelder des Fragenformulars."
            hapticService?.triggerNotification(.warning)
            return false
        }

        let trimmedId = formQuestionId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = formTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = formPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let guidanceText = formGuidance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : formGuidance

        let newQuestion: AssessmentQuestion
        switch formType {
        case .singleChoice:
            let options = [
                ChoiceOption(id: "opt_1", title: formOption1Title, scoreWeight: formOption1Score),
                ChoiceOption(id: "opt_2", title: formOption2Title, scoreWeight: formOption2Score)
            ]
            newQuestion = AssessmentQuestion(
                id: trimmedId,
                dimensionId: formDimensionId,
                type: .singleChoice,
                title: trimmedTitle,
                prompt: trimmedPrompt,
                guidance: guidanceText,
                options: options
            )

        case .multipleChoice:
            let options = [
                ChoiceOption(id: "opt_1", title: formOption1Title, scoreWeight: formOption1Score),
                ChoiceOption(id: "opt_2", title: formOption2Title, scoreWeight: formOption2Score)
            ]
            newQuestion = AssessmentQuestion(
                id: trimmedId,
                dimensionId: formDimensionId,
                type: .multipleChoice,
                title: trimmedTitle,
                prompt: trimmedPrompt,
                guidance: guidanceText,
                options: options,
                minSelectCount: 1,
                maxSelectCount: 2
            )

        case .likertSlider:
            newQuestion = AssessmentQuestion(
                id: trimmedId,
                dimensionId: formDimensionId,
                type: .likertSlider,
                title: trimmedTitle,
                prompt: trimmedPrompt,
                guidance: guidanceText,
                sliderMin: formSliderMin,
                sliderMax: formSliderMax,
                sliderStep: formSliderStep,
                sliderMinLabel: formSliderMinLabel,
                sliderMaxLabel: formSliderMaxLabel,
                sliderDefault: formSliderDefault
            )

        case .shortText:
            newQuestion = AssessmentQuestion(
                id: trimmedId,
                dimensionId: formDimensionId,
                type: .shortText,
                title: trimmedTitle,
                prompt: trimmedPrompt,
                guidance: guidanceText,
                textPlaceholder: formPlaceholder,
                minCharacters: formMinCharacters,
                maxCharacters: formMaxCharacters
            )
        }

        do {
            let updatedCatalog = try active.addingQuestion(newQuestion)
            try catalogStore.saveCustomCatalog(updatedCatalog)
            self.currentCatalog = updatedCatalog
            self.questions = updatedCatalog.questions
            self.hasCustomCatalog = true
            self.statusMessage = "Frage '\(trimmedTitle)' erfolgreich hinzugefügt und in Sandbox gespeichert."
            self.errorMessage = nil
            self.isAddQuestionSheetPresented = false
            hapticService?.triggerNotification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            hapticService?.triggerNotification(.error)
            return false
        }
    }

    @discardableResult
    public func deleteQuestion(id: String) -> Bool {
        guard let active = currentCatalog else { return false }
        do {
            let updatedCatalog = try active.removingQuestion(id: id)
            try catalogStore.saveCustomCatalog(updatedCatalog)
            self.currentCatalog = updatedCatalog
            self.questions = updatedCatalog.questions
            self.hasCustomCatalog = true
            self.statusMessage = "Frage erfolgreich entfernt."
            self.errorMessage = nil
            self.questionToDelete = nil
            revalidateFilter()
            hapticService?.triggerImpact(.medium)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.questionToDelete = nil
            hapticService?.triggerNotification(.error)
            return false
        }
    }

    @discardableResult
    public func resetToBundledCatalog() -> Bool {
        do {
            try catalogStore.resetToBundledCatalog()
            loadCatalog()
            self.statusMessage = "Katalog erfolgreich auf den integrierten Standard zurückgesetzt."
            self.errorMessage = nil
            self.isResetConfirmPresented = false
            revalidateFilter()
            hapticService?.triggerNotification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            hapticService?.triggerNotification(.error)
            return false
        }
    }

    @discardableResult
    public func importCatalogJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            self.errorMessage = "Katalog-Integritätsprüfung fehlgeschlagen / ungültig: Ungültige UTF-8 Textcodierung."
            hapticService?.triggerNotification(.error)
            return false
        }
        do {
            let imported = try catalogStore.importCatalog(from: data)
            self.currentCatalog = imported
            self.questions = imported.questions
            self.dimensions = imported.dimensions
            self.hasCustomCatalog = true
            self.statusMessage = "Katalog mit \(imported.questions.count) Fragen erfolgreich importiert."
            self.errorMessage = nil
            revalidateFilter()
            self.isImportSheetPresented = false
            hapticService?.triggerNotification(.success)
            return true
        } catch {
            self.errorMessage = "Katalog-Integritätsprüfung fehlgeschlagen / ungültig: \(error.localizedDescription)"
            hapticService?.triggerNotification(.error)
            return false
        }
    }

    public func exportCatalogJSON() -> String? {
        guard let data = try? catalogStore.exportCatalogData() else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
