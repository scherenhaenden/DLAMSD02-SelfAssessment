import SwiftUI

/// Screen enabling in-app authoring, inspection, and sandbox management of assessment catalogs (US-15, US-16, ADR-09).
public struct CatalogManagerView: View {
    @ObservedObject public var viewModel: CatalogManagerViewModel
    @Environment(\.appTheme) private var theme

    public init(viewModel: CatalogManagerViewModel) {
        self.viewModel = viewModel
    }

    private var accentColor: Color {
        theme.colorToken(forDimension: "platform").color
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.background.color
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.lg) {
                        headerSection
                        dimensionFilterSection
                        statusBannerSection
                        questionsListSection
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.vertical, theme.spacing.lg)
                    .frame(maxWidth: theme.layout.maxContentWidthiPad)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Katalogverwaltung")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.isImportSheetPresented = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityIdentifier("catalogManager.importButton")
                    .accessibilityLabel("JSON-Katalog importieren")

                    Button(action: {
                        viewModel.resetForm()
                        viewModel.isAddQuestionSheetPresented = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(accentColor)
                    }
                    .accessibilityIdentifier("catalogManager.addQuestionButton")
                    .accessibilityLabel("Neue Frage hinzufügen")
                }

                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.hasCustomCatalog {
                        Button("Zurücksetzen") {
                            viewModel.isResetConfirmPresented = true
                        }
                        .font(.footnote)
                        .foregroundColor(theme.colors.errorFeedback.color)
                        .accessibilityIdentifier("catalogManager.resetButton")
                    }
                }
                #else
                ToolbarItemGroup(placement: .automatic) {
                    if viewModel.hasCustomCatalog {
                        Button("Zurücksetzen") {
                            viewModel.isResetConfirmPresented = true
                        }
                        .font(.footnote)
                        .foregroundColor(theme.colors.errorFeedback.color)
                        .accessibilityIdentifier("catalogManager.resetButton")
                    }

                    Button(action: {
                        viewModel.clearMessages()
                        viewModel.isExportSheetPresented = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("catalogManager.exportButton")
                    .accessibilityLabel("Katalog als JSON exportieren")

                    Button(action: {
                        viewModel.clearMessages()
                        viewModel.isImportSheetPresented = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityIdentifier("catalogManager.importButton")
                    .accessibilityLabel("JSON-Katalog importieren")

                    Button(action: {
                        viewModel.clearMessages()
                        viewModel.resetForm()
                        viewModel.isAddQuestionSheetPresented = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(accentColor)
                    }
                    .accessibilityIdentifier("catalogManager.addQuestionButton")
                    .accessibilityLabel("Neue Frage hinzufügen")
                }
                #endif
            }
            .sheet(isPresented: $viewModel.isAddQuestionSheetPresented) {
                addQuestionSheet
            }
            .sheet(isPresented: $viewModel.isImportSheetPresented) {
                importSheet
            }
            .sheet(isPresented: $viewModel.isExportSheetPresented) {
                exportSheet
            }
            .confirmationDialog(
                "Katalog zurücksetzen?",
                isPresented: $viewModel.isResetConfirmPresented,
                titleVisibility: .visible
            ) {
                Button("Auf Bundle-Standard zurücksetzen", role: .destructive) {
                    viewModel.resetToBundledCatalog()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Alle benutzerdefinierten Fragen und Sandbox-Änderungen werden unwiderruflich gelöscht.")
            }
            .confirmationDialog(
                "Frage löschen?",
                isPresented: Binding(
                    get: { viewModel.questionToDelete != nil },
                    set: { if !$0 { viewModel.questionToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let question = viewModel.questionToDelete {
                    Button("Frage unwiderruflich löschen", role: .destructive) {
                        viewModel.deleteQuestion(id: question.id)
                    }
                }
                Button("Abbrechen", role: .cancel) {
                    viewModel.questionToDelete = nil
                }
            } message: {
                if let question = viewModel.questionToDelete {
                    Text("Möchten Sie die Frage '\(question.title)' wirklich aus dem benutzerdefinierten Katalog entfernen?")
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack {
                Text("Fragenkatalog")
                    .font(.title2.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary.color)

                Spacer()

                Text("\(viewModel.totalQuestionsCount) Fragen")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.12))
                    .foregroundColor(accentColor)
                    .cornerRadius(theme.cornerRadius.small)
                    .accessibilityIdentifier("catalogManager.questionCountBadge")
            }

            if let catalog = viewModel.currentCatalog {
                Text("\(catalog.title) (v\(catalog.version))")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary.color)
            }

            HStack(spacing: theme.spacing.sm) {
                Circle()
                    .fill(viewModel.hasCustomCatalog ? theme.colors.warningFeedback.color : theme.colors.successFeedback.color)
                    .frame(width: 8, height: 8)

                Text(viewModel.hasCustomCatalog ? "Benutzerdefiniert (Sandbox)" : "Standard (App-Bundle)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(theme.colors.textSecondary.color)
                    .accessibilityIdentifier("catalogManager.storageStatusLabel")
            }
            .padding(.top, 2)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surfaceCard.color)
        .cornerRadius(theme.cornerRadius.medium)
    }

    private var dimensionFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.sm) {
                FilterChip(
                    title: "Alle (\(viewModel.questions.count))",
                    isSelected: viewModel.selectedDimensionFilter == nil
                ) {
                    viewModel.selectedDimensionFilter = nil
                }

                ForEach(viewModel.dimensions) { dim in
                    let count = viewModel.questions.filter { $0.dimensionId == dim.id }.count
                    FilterChip(
                        title: "\(dim.name) (\(count))",
                        isSelected: viewModel.selectedDimensionFilter == dim.id
                    ) {
                        viewModel.selectedDimensionFilter = dim.id
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusBannerSection: some View {
        if let status = viewModel.statusMessage {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.colors.successFeedback.color)
                Text(status)
                    .font(.footnote)
                    .foregroundColor(theme.colors.textPrimary.color)
                Spacer()
            }
            .padding(theme.spacing.sm)
            .background(theme.colors.successFeedback.color.opacity(0.1))
            .cornerRadius(theme.cornerRadius.small)
        }

        if let error = viewModel.errorMessage {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(theme.colors.errorFeedback.color)
                Text(error)
                    .font(.footnote)
                    .foregroundColor(theme.colors.textPrimary.color)
                Spacer()
            }
            .padding(theme.spacing.sm)
            .background(theme.colors.errorFeedback.color.opacity(0.1))
            .cornerRadius(theme.cornerRadius.small)
            .accessibilityIdentifier("catalogManager.errorMessageBanner")
        }
    }

    private var questionsListSection: some View {
        LazyVStack(spacing: theme.spacing.md) {
            ForEach(viewModel.filteredQuestions) { question in
                QuestionCardView(
                    question: question,
                    dimensionName: viewModel.dimensions.first(where: { $0.id == question.dimensionId })?.name ?? question.dimensionId,
                    onDelete: viewModel.hasCustomCatalog ? {
                        viewModel.questionToDelete = question
                    } : nil
                )
            }
        }
    }

    // MARK: - Add Question Sheet

    private var addQuestionSheet: some View {
        NavigationStack {
            Form {
                if let error = viewModel.errorMessage {
                    Section {
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(theme.colors.errorFeedback.color)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(theme.colors.errorFeedback.color)
                        }
                    }
                }

                Section(header: Text("Identifikation")) {
                    TextField("Eindeutige ID (z.B. q_custom_01)", text: $viewModel.formQuestionId)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("catalogManager.field.id")

                    Picker("Dimension", selection: $viewModel.formDimensionId) {
                        ForEach(viewModel.dimensions) { dim in
                            Text(dim.name).tag(dim.id)
                        }
                    }
                    .accessibilityIdentifier("catalogManager.picker.dimension")

                    Picker("Fragetyp", selection: $viewModel.formType) {
                        Text("Single Choice").tag(QuestionType.singleChoice)
                        Text("Multiple Choice").tag(QuestionType.multipleChoice)
                        Text("Likert-Skala").tag(QuestionType.likertSlider)
                        Text("Freitext").tag(QuestionType.shortText)
                    }
                    .accessibilityIdentifier("catalogManager.picker.type")
                }

                Section(header: Text("Inhalt")) {
                    TextField("Titel", text: $viewModel.formTitle)
                        .accessibilityIdentifier("catalogManager.field.title")

                    TextField("Fragetext / Prompt", text: $viewModel.formPrompt)
                        .accessibilityIdentifier("catalogManager.field.prompt")

                    TextField("Didaktischer Hinweis (optional)", text: $viewModel.formGuidance)
                        .accessibilityIdentifier("catalogManager.field.guidance")
                }

                if viewModel.formType == .singleChoice || viewModel.formType == .multipleChoice {
                    Section(header: Text("Antwortoptionen (mind. 2)")) {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Option 1 Titel", text: $viewModel.formOption1Title)
                            Stepper("Punkte: \(Int(viewModel.formOption1Score))", value: $viewModel.formOption1Score, in: 0...100, step: 10)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Option 2 Titel", text: $viewModel.formOption2Title)
                            Stepper("Punkte: \(Int(viewModel.formOption2Score))", value: $viewModel.formOption2Score, in: 0...100, step: 10)
                        }
                    }
                } else if viewModel.formType == .likertSlider {
                    Section(header: Text("Skala")) {
                        TextField("Beschriftung Minimum", text: $viewModel.formSliderMinLabel)
                        TextField("Beschriftung Maximum", text: $viewModel.formSliderMaxLabel)
                    }
                } else if viewModel.formType == .shortText {
                    Section(header: Text("Texteinschränkungen")) {
                        Stepper("Min. Zeichen: \(viewModel.formMinCharacters)", value: $viewModel.formMinCharacters, in: 5...50)
                        Stepper("Max. Zeichen: \(viewModel.formMaxCharacters)", value: $viewModel.formMaxCharacters, in: 50...500, step: 50)
                        TextField("Platzhaltertext", text: $viewModel.formPlaceholder)
                    }
                }
            }
            .navigationTitle("Neue Frage")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        viewModel.isAddQuestionSheetPresented = false
                    }
                    .accessibilityIdentifier("catalogManager.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        viewModel.saveNewQuestion()
                    }
                    .disabled(!viewModel.isFormValid)
                    .accessibilityIdentifier("catalogManager.saveQuestionButton")
                }
            }
        }
    }

    // MARK: - Import Sheet

    private var importSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Fügen Sie ein vollständiges JSON-Katalog-Payload ein, um es zu importieren. Bestehende Daten werden zuvor als .bak gesichert.")
                    .font(.footnote)
                    .foregroundColor(theme.colors.textSecondary.color)

                if let error = viewModel.errorMessage {
                    HStack(alignment: .top, spacing: theme.spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(theme.colors.errorFeedback.color)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(theme.colors.errorFeedback.color)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(theme.spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                            .fill(theme.colors.errorFeedback.color.opacity(0.12))
                    )
                    .accessibilityIdentifier("catalogManager.importErrorMessage")
                }

                TextEditor(text: $viewModel.importJSONText)
                    .font(.system(.caption, design: .monospaced))
                    .padding(theme.spacing.xs)
                    .background(theme.colors.surfaceCard.color)
                    .cornerRadius(theme.cornerRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                            .stroke(theme.colors.textSecondary.color.opacity(0.2), lineWidth: 1)
                    )
                    .accessibilityIdentifier("catalogManager.importEditor")

                Spacer()
            }
            .padding(theme.spacing.md)
            .navigationTitle("JSON-Katalog importieren")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        viewModel.isImportSheetPresented = false
                    }
                    .accessibilityIdentifier("catalogManager.cancelImportButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importieren") {
                        viewModel.importCatalogJSON(viewModel.importJSONText)
                    }
                    .disabled(viewModel.importJSONText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("catalogManager.executeImportButton")
                }
            }
        }
    }

    // MARK: - Export Sheet

    private var exportSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Aktiver Fragenkatalog im JSON-Format zur Sicherung oder Weiterverwendung.")
                    .font(.footnote)
                    .foregroundColor(theme.colors.textSecondary.color)

                ScrollView {
                    Text(viewModel.exportCatalogJSON() ?? "Kein aktiver Katalog exportierbar.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(theme.colors.textPrimary.color)
                        .padding(theme.spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.colors.surfaceCard.color)
                        .cornerRadius(theme.cornerRadius.small)
                }
                .accessibilityIdentifier("catalogManager.exportContent")

                if let json = viewModel.exportCatalogJSON() {
                    ShareLink(item: json, subject: Text("DevProfile Katalog"), message: Text("Exportierter Selbsteinschätzungskatalog")) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Katalog teilen / exportieren")
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(accentColor)
                        .foregroundColor(theme.colors.onAccent.color)
                        .cornerRadius(theme.cornerRadius.medium)
                    }
                    .accessibilityIdentifier("catalogManager.shareExportButton")
                }
            }
            .padding(theme.spacing.md)
            .navigationTitle("Katalog exportieren")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        viewModel.isExportSheetPresented = false
                    }
                    .accessibilityIdentifier("catalogManager.doneExportButton")
                }
            }
        }
    }
}

// MARK: - Helper Subviews

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.appTheme) private var theme

    private var accentColor: Color {
        theme.colorToken(forDimension: "platform").color
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? accentColor : theme.colors.surfaceCard.color)
                .foregroundColor(isSelected ? theme.colors.onAccent.color : theme.colors.textPrimary.color)
                .cornerRadius(theme.cornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                        .stroke(isSelected ? Color.clear : theme.colors.textSecondary.color.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct QuestionCardView: View {
    let question: AssessmentQuestion
    let dimensionName: String
    let onDelete: (() -> Void)?
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack {
                Text(question.title)
                    .font(.headline)
                    .foregroundColor(theme.colors.textPrimary.color)
                Spacer()
                Text(typeLabel(question.type))
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.colors.textSecondary.color.opacity(0.12))
                    .foregroundColor(theme.colors.textSecondary.color)
                    .cornerRadius(4)

                if let deleteAction = onDelete {
                    Button(action: deleteAction) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(theme.colors.errorFeedback.color)
                    }
                    .accessibilityLabel("Frage \(question.id) löschen")
                }
            }

            Text(question.prompt)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary.color)
                .lineLimit(2)

            HStack {
                Text(dimensionName)
                    .font(.caption2)
                    .foregroundColor(theme.colorToken(forDimension: question.dimensionId).color)
                Spacer()
                Text("ID: \(question.id)")
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary.color)
            }
            .padding(.top, 4)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surfaceCard.color)
        .cornerRadius(theme.cornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(theme.colors.textSecondary.color.opacity(0.15), lineWidth: 1)
        )
    }

    private func typeLabel(_ type: QuestionType) -> String {
        switch type {
        case .singleChoice: return "Single Choice"
        case .multipleChoice: return "Multiple Choice"
        case .likertSlider: return "Likert-Skala"
        case .shortText: return "Freitext"
        }
    }
}
