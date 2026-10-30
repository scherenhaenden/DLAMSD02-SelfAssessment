import SwiftUI

/// Main sequential assessment coordinator screen guiding the user through all 24 questions
/// with progress tracking, validation gating, and dimension transitions.
public struct AssessmentFlowView<VM: AssessmentViewModelProtocol>: View {
    @ObservedObject public var viewModel: VM
    @Environment(\.appTheme) private var theme

    public init(viewModel: VM) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.background.color
                    .ignoresSafeArea()

                switch viewModel.state {
                case .idle:
                    idleView

                case .loading:
                    loadingView

                case .inProgress:
                    inProgressView

                case .completed(let record):
                    completedView(record: record)

                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Self-Assessment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                if viewModel.state == .idle {
                    viewModel.loadCatalog()
                }
            }
        }
    }

    // MARK: - Subviews

    private var idleView: some View {
        VStack(spacing: theme.spacing.md) {
            Text("Willkommen zum DevProfile Self-Assessment")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary.color)
                .multilineTextAlignment(.center)

            Text("Starte jetzt die Selbsteinschätzung über 4 Dimensionen mit 24 Fragen.")
                .font(.body)
                .foregroundColor(theme.colors.textSecondary.color)
                .multilineTextAlignment(.center)

            Button {
                viewModel.loadCatalog()
            } label: {
                Text("Assessment starten")
                    .font(.headline)
                    .foregroundColor(theme.colors.surfaceCard.color)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(theme.colorToken(forDimension: "architecture").color)
                    .cornerRadius(theme.cornerRadius.medium)
            }
            .padding(.top, theme.spacing.md)
            .accessibilityIdentifier("flow.startButton")
        }
        .padding(theme.spacing.lg)
    }

    private var loadingView: some View {
        VStack(spacing: theme.spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Fragenkatalog wird geladen...")
                .font(.body)
                .foregroundColor(theme.colors.textSecondary.color)
        }
    }

    private var inProgressView: some View {
        VStack(spacing: 0) {
            // Header: Progress bar, Counter & Dimension badge
            topProgressHeader
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.sm)
                .background(theme.colors.surfaceCard.color)

            Divider()

            // Scrollable Question Container
            ScrollView {
                if let question = viewModel.currentQuestion {
                    AssessmentQuestionContainerView(viewModel: viewModel, question: question)
                        .padding(theme.spacing.lg)
                }
            }

            Divider()

            // Sticky Bottom Navigation Actions
            bottomNavigationToolbar
                .padding(theme.spacing.md)
                .background(theme.colors.surfaceCard.color)
        }
    }

    private var topProgressHeader: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack {
                if let dimension = viewModel.currentDimension {
                    Text(dimension.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(theme.colorToken(forDimension: dimension.id).color.opacity(0.15))
                        )
                        .foregroundColor(theme.colorToken(forDimension: dimension.id).color)
                        .accessibilityIdentifier("flow.dimensionBadge")
                }

                Spacer()

                Text("Frage \(viewModel.currentQuestionIndex + 1) / \(viewModel.totalQuestions)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textSecondary.color)
                    .accessibilityIdentifier("flow.counterPill")
            }

            ProgressView(value: viewModel.progress)
                .tint(currentDimensionColor)
                .accessibilityIdentifier("flow.progressBar")
                .accessibilityLabel("Fortschritt: \(Int(viewModel.progress * 100)) Prozent")
        }
    }

    private var bottomNavigationToolbar: some View {
        HStack(spacing: theme.spacing.md) {
            // Back Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.goBack()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Zurück")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(viewModel.canGoBack ? theme.colors.textPrimary.color : theme.colors.textSecondary.color.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                        .stroke(viewModel.canGoBack ? theme.colors.textSecondary.color.opacity(0.4) : theme.colors.textSecondary.color.opacity(0.15), lineWidth: 1)
                )
            }
            .disabled(!viewModel.canGoBack)
            .accessibilityIdentifier("flow.backButton")

            // Next / Finish Button
            if viewModel.isLastQuestion {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.submitAssessment()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Abschließen")
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .fill(viewModel.isCurrentAnswerValid ? theme.colors.successFeedback.color : theme.colors.textSecondary.color.opacity(0.3))
                    )
                }
                .disabled(!viewModel.isCurrentAnswerValid)
                .accessibilityIdentifier("flow.submitButton")
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.advance()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Weiter")
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .fill(viewModel.canGoForward ? theme.colorToken(forDimension: "architecture").color : theme.colors.textSecondary.color.opacity(0.3))
                    )
                }
                .disabled(!viewModel.canGoForward)
                .accessibilityIdentifier("flow.nextButton")
            }
        }
    }

    private func completedView(record: AssessmentRecord) -> some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(theme.colors.successFeedback.color)
                    .padding(.top, theme.spacing.xl)

                VStack(spacing: theme.spacing.xs) {
                    Text("Self-Assessment abgeschlossen!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary.color)

                    Text("Dein diagnostisches Entwicklerprofil wurde erfolgreich synthetisiert.")
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary.color)
                        .multilineTextAlignment(.center)
                }

                // Archetype Card
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Diagnostizierter Archetyp")
                                .font(.caption)
                                .foregroundColor(theme.colors.textSecondary.color)
                            Text(record.archetype.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(theme.colors.textPrimary.color)
                        }
                        Spacer()
                        Text(String(format: "%.1f %%", record.overallScore))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colorToken(forDimension: "architecture").color)
                    }

                    Text(record.archetype.description)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary.color)
                }
                .padding(theme.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .fill(theme.colors.surfaceCard.color)
                )

                // Restart Button
                Button {
                    viewModel.reset()
                    viewModel.loadCatalog()
                } label: {
                    Text("Assessment wiederholen")
                        .font(.headline)
                        .foregroundColor(theme.colors.surfaceCard.color)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(theme.colorToken(forDimension: "architecture").color)
                        .cornerRadius(theme.cornerRadius.medium)
                }
                .padding(.top, theme.spacing.md)
                .accessibilityIdentifier("flow.resetButton")
            }
            .padding(theme.spacing.lg)
            .accessibilityIdentifier("flow.completionView")
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.warningFeedback.color)

            Text("Fehler aufgetreten")
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary.color)

            Text(message)
                .font(.body)
                .foregroundColor(theme.colors.textSecondary.color)
                .multilineTextAlignment(.center)

            Button {
                viewModel.loadCatalog()
            } label: {
                Text("Erneut versuchen")
                    .font(.headline)
                    .foregroundColor(theme.colors.surfaceCard.color)
                    .frame(maxWidth: 200, minHeight: 44)
                    .background(theme.colorToken(forDimension: "architecture").color)
                    .cornerRadius(theme.cornerRadius.medium)
            }
            .accessibilityIdentifier("flow.retryButton")
        }
        .padding(theme.spacing.lg)
    }

    private var currentDimensionColor: Color {
        if let dimension = viewModel.currentDimension {
            return theme.colorToken(forDimension: dimension.id).color
        }
        return theme.colorToken(forDimension: "architecture").color
    }
}
