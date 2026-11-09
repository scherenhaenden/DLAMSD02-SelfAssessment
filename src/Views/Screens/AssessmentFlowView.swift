import SwiftUI

/// Main sequential assessment coordinator screen guiding the user through all 24 questions
/// with progress tracking, validation gating, and dimension transitions.
public struct AssessmentFlowView<VM: AssessmentViewModelProtocol>: View {
    @ObservedObject public var viewModel: VM
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.hapticFeedback) private var envHapticService

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
                if !viewModel.hasExplicitHapticService {
                    viewModel.hapticService = envHapticService
                }
            }
        }
    }

    // MARK: - Subviews

    private var idleView: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                // Header Icon & Title
                VStack(spacing: theme.spacing.xs) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundColor(theme.colorToken(forDimension: "architecture").color)
                        .padding(.top, theme.spacing.md)

                    Text("Willkommen zum DevProfile Self-Assessment")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary.color)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("flow.welcomeTitle")

                    Text("Strukturierte Selbsteinschätzung Deiner Software-Engineering-Kompetenzen über 4 Kerndimensionen.")
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary.color)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("flow.welcomeDescription")
                }

                // Information & Dimension Overview Card
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Übersicht des Assessments")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary.color)

                    Divider()

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        infoBullet(icon: "square.grid.2x2", title: "4 Dimensionen", detail: "Architecture, Platform, Quality & Agile")
                        infoBullet(icon: "list.number", title: "24 Fragen", detail: "Single Choice, Multi-Select, Likert & Freitext")
                        infoBullet(icon: "clock", title: "ca. 10–15 Min.", detail: "Reflexiv und ohne künstlichen Zeitdruck")
                    }
                }
                .padding(theme.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .fill(theme.colors.surfaceCard.color)
                )

                // Start Action Button
                Button {
                    viewModel.loadCatalog()
                } label: {
                    HStack(spacing: 6) {
                        Text("Assessment starten")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(theme.colors.onAccent.color)
                    .frame(maxWidth: .infinity, minHeight: theme.layout.primaryButtonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .fill(theme.colorToken(forDimension: "architecture").color)
                    )
                }
                .buttonStyle(TactileButtonStyle())
                .padding(.top, theme.spacing.sm)
                .accessibilityIdentifier("flow.startButton")
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: theme.layout.maxContentWidthiPad)
            .frame(maxWidth: .infinity)
        }
    }

    private func infoBullet(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(theme.colorToken(forDimension: "architecture").color)
                .frame(width: 20)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary.color)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary.color)
            }
        }
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
                .frame(maxWidth: theme.layout.maxContentWidthiPad)
                .frame(maxWidth: .infinity)
                .background(theme.colors.surfaceCard.color)

            Divider()

            // Scrollable Question Container
            ScrollView {
                if let question = viewModel.currentQuestion {
                    AssessmentQuestionContainerView(viewModel: viewModel, question: question)
                        .id(question.id)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                        .padding(theme.spacing.lg)
                        .frame(maxWidth: theme.layout.maxContentWidthiPad)
                        .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // Sticky Bottom Navigation Actions
            bottomNavigationToolbar
                .padding(theme.spacing.md)
                .frame(maxWidth: theme.layout.maxContentWidthiPad)
                .frame(maxWidth: .infinity)
                .background(theme.colors.surfaceCard.color)
        }
    }

    private func performMotionAwareAction(_ action: () -> Void) {
        if reduceMotion {
            action()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
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
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: dimension.id)
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
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75), value: viewModel.progress)
                .accessibilityIdentifier("flow.progressBar")
                .accessibilityLabel("Fortschritt: \(Int(viewModel.progress * 100)) Prozent")
        }
    }

    private var bottomNavigationToolbar: some View {
        HStack(spacing: theme.spacing.md) {
            // Back Button
            Button {
                performMotionAwareAction {
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
            .buttonStyle(TactileButtonStyle())
            .disabled(!viewModel.canGoBack)
            .accessibilityIdentifier("flow.backButton")

            // Next / Finish Button
            if viewModel.isLastQuestion {
                Button {
                    performMotionAwareAction {
                        viewModel.submitAssessment()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Abschließen")
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(viewModel.isCurrentAnswerValid ? theme.colors.onAccent.color : theme.colors.textSecondary.color.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .fill(viewModel.isCurrentAnswerValid ? theme.colors.successFeedback.color : theme.colors.textSecondary.color.opacity(0.18))
                    )
                }
                .buttonStyle(TactileButtonStyle())
                .disabled(!viewModel.isCurrentAnswerValid)
                .accessibilityIdentifier("flow.submitButton")
            } else {
                Button {
                    performMotionAwareAction {
                        viewModel.advance()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Weiter")
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .foregroundColor(viewModel.canGoForward ? theme.colors.onAccent.color : theme.colors.textSecondary.color.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .fill(viewModel.canGoForward ? currentDimensionColor : theme.colors.textSecondary.color.opacity(0.18))
                    )
                }
                .buttonStyle(TactileButtonStyle())
                .disabled(!viewModel.canGoForward)
                .accessibilityIdentifier("flow.nextButton")
            }
        }
    }

    private func completedView(record: AssessmentRecord) -> some View {
        AssessmentResultView(
            record: record,
            catalog: viewModel.catalog,
            persistenceWarning: viewModel.persistenceError,
            theme: theme,
            onRestart: {
                viewModel.reset()
                viewModel.loadCatalog()
            },
            onRetryPersistence: {
                _ = viewModel.retryPersistence()
            }
        )
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
                    .foregroundColor(theme.colors.onAccent.color)
                    .frame(maxWidth: 200, minHeight: 44)
                    .background(theme.colorToken(forDimension: "architecture").color)
                    .cornerRadius(theme.cornerRadius.medium)
            }
            .buttonStyle(TactileButtonStyle())
            .accessibilityIdentifier("flow.retryButton")
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: theme.layout.maxContentWidthiPad)
        .frame(maxWidth: .infinity)
    }

    private var currentDimensionColor: Color {
        if let dimension = viewModel.currentDimension {
            return theme.colorToken(forDimension: dimension.id).color
        }
        return theme.colorToken(forDimension: "architecture").color
    }
}
