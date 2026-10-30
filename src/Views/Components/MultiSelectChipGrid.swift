import SwiftUI

/// An accessible, state-explicit multi-selection grid with interactive chips and selection boundary indicators.
public struct MultiSelectChipGrid: View {
    @Environment(\.appTheme) private var theme

    public let options: [ChoiceOption]
    public let selectedIds: Set<String>
    public let minSelectCount: Int
    public let maxSelectCount: Int
    public let dimensionId: String?
    public let onToggle: (String) -> Void

    public init(
        options: [ChoiceOption],
        selectedIds: Set<String>,
        minSelectCount: Int? = nil,
        maxSelectCount: Int? = nil,
        dimensionId: String? = nil,
        onToggle: @escaping (String) -> Void
    ) {
        self.options = options
        self.selectedIds = selectedIds
        self.minSelectCount = minSelectCount ?? 1
        self.maxSelectCount = maxSelectCount ?? options.count
        self.dimensionId = dimensionId
        self.onToggle = onToggle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Selection status header
            HStack {
                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(isWithinBounds ? theme.colors.textSecondary.color : theme.colors.warningFeedback.color)
                Spacer()
                Text("\(selectedIds.count)/\(maxSelectCount)")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(isWithinBounds ? accentColor : theme.colors.warningFeedback.color)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Selection status: \(selectedIds.count) of maximum \(maxSelectCount) selected. Required minimum: \(minSelectCount).")

            // Grid of selectable chips
            LazyVGrid(
                columns: [
                    GridItem(.flexible(minimum: 140), spacing: theme.spacing.sm),
                    GridItem(.flexible(minimum: 140), spacing: theme.spacing.sm)
                ],
                spacing: theme.spacing.sm
            ) {
                ForEach(options) { option in
                    let isSelected = selectedIds.contains(option.id)
                    Button {
                        onToggle(option.id)
                    } label: {
                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? accentColor : theme.colors.textSecondary.color.opacity(0.4))
                                .accessibilityHidden(true)

                            Text(option.title)
                                .font(.subheadline)
                                .foregroundColor(theme.colors.textPrimary.color)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, theme.spacing.md)
                        .padding(.vertical, theme.spacing.sm)
                        .frame(minHeight: theme.layout.minTouchTargetSize)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius.small, style: .continuous)
                                .fill(isSelected ? accentColor.opacity(0.12) : theme.colors.surfaceCard.color)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius.small, style: .continuous)
                                .strokeBorder(
                                    isSelected ? accentColor : theme.colors.textSecondary.color.opacity(0.2),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
                    .accessibilityHint(isSelected ? "Selected. Double tap to deselect." : "Not selected. Double tap to select.")
                }
            }
        }
    }

    private var isWithinBounds: Bool {
        selectedIds.count >= minSelectCount && selectedIds.count <= maxSelectCount
    }

    private var statusText: String {
        if minSelectCount == maxSelectCount {
            return "Wähle genau \(minSelectCount) Optionen"
        } else if minSelectCount > 1 {
            return "Wähle zwischen \(minSelectCount) und \(maxSelectCount) Optionen"
        } else {
            return "Mehrfachauswahl (maximal \(maxSelectCount))"
        }
    }

    private var accentColor: Color {
        if let dim = dimensionId {
            return theme.colorToken(forDimension: dim).color
        }
        return theme.colors.textPrimary.color
    }
}
