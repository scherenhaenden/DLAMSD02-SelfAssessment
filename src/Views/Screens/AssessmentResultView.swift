import SwiftUI

/// Comprehensive diagnostic results dashboard displaying overall score, archetype card,
/// multi-dimensional competency bars, and pedagogical recommendations.
public struct AssessmentResultView: View {
    public let record: AssessmentRecord
    public let catalog: AssessmentCatalog?
    public let onRestart: () -> Void
    public let theme: any AppThemeProtocol

    public init(
        record: AssessmentRecord,
        catalog: AssessmentCatalog? = nil,
        theme: any AppThemeProtocol = AppTheme(),
        onRestart: @escaping () -> Void
    ) {
        self.record = record
        self.catalog = catalog
        self.theme = theme
        self.onRestart = onRestart
    }

    public var formattedDuration: String {
        let totalSeconds = Int(record.durationSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes) Min. \(seconds) Sek."
        } else {
            return "\(seconds) Sek."
        }
    }

    public var dimensionsToDisplay: [AssessmentDimension] {
        if let catalog = catalog, !catalog.dimensions.isEmpty {
            return catalog.dimensions
        }
        return AssessmentDimension.standardDimensions
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                // Hero Celebration Header
                heroHeader

                // Dominant Archetype Card
                ArchetypeCardView(
                    archetype: record.archetype,
                    overallScore: record.overallScore,
                    theme: theme
                )

                // Competency Dashboard
                competencyDashboard

                // Pedagogical Recommendations
                PedagogicalRecommendationsView(
                    dimensionScores: record.dimensionScores,
                    theme: theme
                )

                // Action Bar: Restart Assessment
                bottomActionBar
            }
            .padding(theme.spacing.lg)
        }
        .background(theme.colors.background.color)
        .accessibilityIdentifier("assessmentResultView")
    }

    // MARK: - Subviews

    private var heroHeader: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundColor(theme.colors.successFeedback.color)
                .padding(.top, theme.spacing.xs)

            VStack(spacing: theme.spacing.xs) {
                Text("Self-Assessment abgeschlossen!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary.color)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("flow.completionTitle")

                Text("Dein diagnostisches Entwicklerprofil wurde erfolgreich synthetisiert.")
                    .font(.subheadline)
                    .foregroundColor(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
            }

            // Duration & Timestamp Pill
            HStack(spacing: theme.spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Dauer: \(formattedDuration)")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(theme.colors.textSecondary.color)

                Text("•")
                    .foregroundColor(theme.colors.textSecondary.color)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(record.completedAt, style: .date)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(theme.colors.textSecondary.color)
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(theme.colors.surfaceCard.color)
            )
        }
    }

    private var competencyDashboard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.headline)
                    .foregroundColor(theme.colorToken(forDimension: "architecture").color)

                Text("Kompetenz-Dashboard")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary.color)

                Spacer()

                Text("4 Dimensionen")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary.color)
            }

            VStack(spacing: theme.spacing.sm) {
                ForEach(dimensionsToDisplay) { dimension in
                    let score = record.dimensionScores[dimension.id] ?? 0.0
                    DimensionScoreBarView(
                        dimensionId: dimension.id,
                        title: dimension.name,
                        iconSystemName: dimension.iconName,
                        score: score,
                        theme: theme
                    )
                }
            }
            .padding(theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .fill(theme.colors.surfaceCard.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(theme.colors.textSecondary.color.opacity(0.12), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("competencyDashboard")
    }

    private var bottomActionBar: some View {
        Button(action: onRestart) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline)
                Text("Assessment wiederholen")
                    .font(.headline)
            }
            .foregroundColor(theme.colors.onAccent.color)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .fill(theme.colorToken(forDimension: "architecture").color)
            )
        }
        .buttonStyle(TactileButtonStyle())
        .accessibilityLabel("Assessment wiederholen")
        .accessibilityIdentifier("flow.resetButton")
        .padding(.top, theme.spacing.sm)
    }
}
