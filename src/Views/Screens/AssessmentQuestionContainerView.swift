import SwiftUI

/// Container view that dynamically renders the appropriate atomic input component
/// for a given question based on its polymorphic type.
public struct AssessmentQuestionContainerView<VM: AssessmentViewModelProtocol>: View {
    @ObservedObject public var viewModel: VM
    public let question: AssessmentQuestion
    @Environment(\.appTheme) private var theme

    public init(viewModel: VM, question: AssessmentQuestion) {
        self.viewModel = viewModel
        self.question = question
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            // Question Header Card
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(question.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary.color)
                    .accessibilityIdentifier("flow.questionTitle")

                Text(question.prompt)
                    .font(.body)
                    .foregroundColor(theme.colors.textSecondary.color)
                    .accessibilityIdentifier("flow.questionPrompt")

                if let guidance = question.guidance, !guidance.isEmpty {
                    HStack(alignment: .top, spacing: theme.spacing.xs) {
                        Image(systemName: "info.circle")
                            .foregroundColor(dimensionAccentColor)
                            .accessibilityHidden(true)
                        Text(guidance)
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary.color)
                    }
                    .padding(theme.spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.colors.surfaceCard.color)
                    )
                    .padding(.top, theme.spacing.xs)
                }
            }

            // Polymorphic Interactive Component
            switch question.type {
            case .singleChoice:
                singleChoiceSection

            case .multipleChoice:
                multipleChoiceSection

            case .likertSlider:
                likertSliderSection

            case .shortText:
                shortTextSection
            }
        }
    }

    // MARK: - Private Component Embeddings

    private var singleChoiceSection: some View {
        VStack(spacing: theme.spacing.sm) {
            if let options = question.options {
                ForEach(options) { option in
                    let isSelected: Bool = {
                        if case .singleChoice(let selectedId) = viewModel.answers[question.id] {
                            return selectedId == option.id
                        }
                        return false
                    }()

                    ChoiceOptionButton(
                        option: option,
                        isSelected: isSelected,
                        dimensionId: question.dimensionId,
                        onSelect: {
                            viewModel.recordSingleChoice(questionId: question.id, selectedOptionId: option.id)
                        }
                    )
                }
            }
        }
    }

    private var multipleChoiceSection: some View {
        let currentSelectedIds: Set<String> = {
            if case .multipleChoice(let ids) = viewModel.answers[question.id] {
                return Set(ids)
            }
            return []
        }()

        return MultiSelectChipGrid(
            options: question.options ?? [],
            selectedIds: currentSelectedIds,
            minSelectCount: question.minSelectCount ?? 1,
            maxSelectCount: question.maxSelectCount ?? (question.options?.count ?? 4),
            dimensionId: question.dimensionId,
            onToggle: { optionId in
                viewModel.toggleMultipleChoice(questionId: question.id, optionId: optionId)
            }
        )
    }

    private var likertSliderSection: some View {
        let currentValue: Double = {
            if case .steppedSlider(let val) = viewModel.answers[question.id] {
                return val
            }
            return question.sliderDefault ?? question.sliderMin ?? 1.0
        }()

        return LikertSliderCard(
            value: currentValue,
            minVal: question.sliderMin ?? 1.0,
            maxVal: question.sliderMax ?? 5.0,
            step: question.sliderStep ?? 1.0,
            minLabel: question.sliderMinLabel,
            maxLabel: question.sliderMaxLabel,
            dimensionId: question.dimensionId,
            onValueChange: { newValue in
                viewModel.recordSliderValue(questionId: question.id, value: newValue)
            }
        )
        .onAppear {
            if case .steppedSlider = viewModel.answers[question.id] {
                // Already recorded
            } else {
                viewModel.recordSliderValue(questionId: question.id, value: currentValue)
            }
        }
    }

    private var shortTextSection: some View {
        let currentText: String = {
            if case .shortText(let txt) = viewModel.answers[question.id] {
                return txt
            }
            return ""
        }()

        return ShortTextPromptCard(
            text: currentText,
            minCharacters: question.minCharacters ?? 15,
            maxCharacters: question.maxCharacters ?? 350,
            placeholder: question.textPlaceholder,
            dimensionId: question.dimensionId,
            onTextChange: { newText in
                viewModel.recordShortText(questionId: question.id, text: newText)
            }
        )
    }

    private var dimensionAccentColor: Color {
        theme.colorToken(forDimension: question.dimensionId).color
    }
}
