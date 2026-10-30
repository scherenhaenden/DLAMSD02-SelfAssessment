import SwiftUI

/// An accessible, state-explicit button representing a single selectable option in an assessment.
public struct ChoiceOptionButton: View {
    @Environment(\.appTheme) private var theme

    public let option: ChoiceOption
    public let isSelected: Bool
    public let dimensionId: String?
    public let onSelect: () -> Void

    public init(
        option: ChoiceOption,
        isSelected: Bool,
        dimensionId: String? = nil,
        onSelect: @escaping () -> Void
    ) {
        self.option = option
        self.isSelected = isSelected
        self.dimensionId = dimensionId
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: theme.spacing.md) {
                // Radio indicator icon
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? accentColor : theme.colors.textSecondary.color.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 14, height: 14)
                    }
                }
                .accessibilityHidden(true)

                // Option title text
                Text(option.title)
                    .font(.body)
                    .foregroundColor(theme.colors.textPrimary.color)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .frame(minHeight: theme.layout.primaryButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.12) : theme.colors.surfaceCard.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium, style: .continuous)
                    .strokeBorder(
                        isSelected ? accentColor : theme.colors.textSecondary.color.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("choiceOption.\(option.id)")
        .accessibilityElement(children: .combine)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .accessibilityHint(isSelected ? "Selected single choice option" : "Double tap to select this option")
    }

    private var accentColor: Color {
        if let dim = dimensionId {
            return theme.colorToken(forDimension: dim).color
        }
        return theme.colors.textPrimary.color
    }
}
