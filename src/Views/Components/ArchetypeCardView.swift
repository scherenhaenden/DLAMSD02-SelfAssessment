import SwiftUI

/// Accessible card presenting the evaluated dominant developer archetype, strengths, and growth areas.
public struct ArchetypeCardView: View {
    public let archetype: ArchetypeProfile
    public let overallScore: Double
    public let theme: any AppThemeProtocol

    public init(
        archetype: ArchetypeProfile,
        overallScore: Double,
        theme: any AppThemeProtocol = AppTheme()
    ) {
        self.archetype = archetype
        self.overallScore = min(100.0, max(0.0, overallScore))
        self.theme = theme
    }

    public var body: some View {
        let accentColor = theme.colorToken(forDimension: archetype.dominantDimensionId).color

        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Header: Icon + Titles + Score Badge
            HStack(alignment: .top, spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: archetype.badgeSymbol)
                        .font(.title2)
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Diagnostizierter Archetyp")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textSecondary.color)
                        .accessibilityLabel("Diagnostizierter Archetyp")

                    Text(archetype.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary.color)

                    Text(archetype.subtitle)
                        .font(.caption)
                        .foregroundColor(accentColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f %%", overallScore))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)

                    Text("Gesamt")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary.color)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Diagnostizierter Archetyp: \(archetype.title), \(archetype.subtitle). Gesamtpunktzahl: \(String(format: "%.1f", overallScore)) Prozent.")

            // Description
            Text(archetype.description)
                .font(.subheadline)
                .foregroundColor(theme.colors.textPrimary.color)
                .lineSpacing(3)

            Divider()

            // Strengths (Stärken)
            if !archetype.strengths.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(theme.colors.successFeedback.color)

                        Text("Kernstärken")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary.color)
                            .textCase(.uppercase)
                    }

                    ForEach(archetype.strengths, id: \.self) { strength in
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            Text("•")
                                .foregroundColor(theme.colors.successFeedback.color)
                            Text(strength)
                                .font(.caption)
                                .foregroundColor(theme.colors.textSecondary.color)
                        }
                    }
                }
            }

            // Growth Opportunities (Entwicklungspotenziale)
            if !archetype.growthOpportunities.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(theme.colors.warningFeedback.color)

                        Text("Entwicklungspotenziale")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary.color)
                            .textCase(.uppercase)
                    }

                    ForEach(archetype.growthOpportunities, id: \.self) { opportunity in
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            Text("•")
                                .foregroundColor(theme.colors.warningFeedback.color)
                            Text(opportunity)
                                .font(.caption)
                                .foregroundColor(theme.colors.textSecondary.color)
                        }
                    }
                }
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                .fill(theme.colors.surfaceCard.color)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                .stroke(theme.colors.textSecondary.color.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("archetypeCard")
    }
}
