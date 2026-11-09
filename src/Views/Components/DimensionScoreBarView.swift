import SwiftUI

/// Accessible graphical progress bar visualizing a single competency dimension score.
public struct DimensionScoreBarView: View {
    public let dimensionId: String
    public let title: String
    public let iconSystemName: String
    public let score: Double
    public let theme: any AppThemeProtocol

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    public init(
        dimensionId: String,
        title: String,
        iconSystemName: String,
        score: Double,
        theme: any AppThemeProtocol = AppTheme()
    ) {
        self.dimensionId = dimensionId
        self.title = title
        self.iconSystemName = iconSystemName
        self.score = min(100.0, max(0.0, score))
        self.theme = theme
    }

    public var normalizedRatio: CGFloat {
        CGFloat(score / 100.0)
    }

    public var formattedScore: String {
        String(format: "%.1f %%", score)
    }

    public var body: some View {
        let dimensionColor = theme.colorToken(forDimension: dimensionId).color

        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: iconSystemName)
                    .font(.subheadline)
                    .foregroundColor(dimensionColor)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary.color)

                Spacer()

                Text(formattedScore)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(dimensionColor)
            }

            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let fillWidth = max(0.0, min(availableWidth, availableWidth * normalizedRatio))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                        .fill(theme.colors.textSecondary.color.opacity(0.15))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                        .fill(dimensionColor)
                        .frame(width: fillWidth, height: 12)
                        .animation(systemReduceMotion ? nil : .easeOut(duration: 0.6), value: normalizedRatio)
                }
            }
            .frame(height: 12)
        }
        .padding(.vertical, theme.spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(formattedScore)")
        .accessibilityValue(formattedScore)
        .accessibilityIdentifier("dimensionBar.\(dimensionId)")
    }
}
