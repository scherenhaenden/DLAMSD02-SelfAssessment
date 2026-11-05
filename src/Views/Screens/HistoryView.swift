import SwiftUI

/// Displays a chronological log of all completed self-assessments, including dominant archetypes,
/// multi-dimensional score distributions, and temporal delta comparisons in percentage points (pp).
public struct HistoryView: View {
    public let historyStore: any HistoryStoreProtocol
    public let theme: any AppThemeProtocol

    @State private var records: [AssessmentRecord] = []
    @State private var errorMessage: String?
    @State private var showClearConfirmation: Bool = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    public init(
        historyStore: any HistoryStoreProtocol = UserDefaultsHistoryStore(),
        theme: any AppThemeProtocol = AppTheme()
    ) {
        self.historyStore = historyStore
        self.theme = theme
    }

    public var body: some View {
        Group {
            if let error = errorMessage {
                errorStateView(message: error)
            } else if records.isEmpty {
                emptyStateView
            } else {
                recordsListView
            }
        }
        .background(theme.colors.background.color.ignoresSafeArea())
        .onAppear {
            loadRecords()
        }
        .alert(isPresented: $showClearConfirmation) {
            Alert(
                title: Text("Verlauf löschen"),
                message: Text("Möchtest du alle gespeicherten Assessment-Ergebnisse wirklich unwiderruflich löschen?"),
                primaryButton: .destructive(Text("Löschen")) {
                    clearAllHistory()
                },
                secondaryButton: .cancel(Text("Abbrechen"))
            )
        }
        .accessibilityIdentifier("historyView")
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.md) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56, weight: .semibold))
                .foregroundColor(theme.colors.textSecondary.color)
                .accessibilityHidden(true)

            Text("Keine Verlaufsdaten vorhanden")
                .font(.title3.weight(.bold))
                .foregroundColor(theme.colors.textPrimary.color)

            Text("Absolviere dein erstes Self-Assessment, um deinen Kompetenzverlauf und deine zeitliche Entwicklung zu dokumentieren.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.textSecondary.color)
                .padding(.horizontal, theme.spacing.xl)

            Spacer()
        }
        .frame(maxWidth: theme.layout.maxContentWidthiPad)
        .padding(theme.spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Keine Verlaufsdaten vorhanden. Absolviere ein Assessment, um deinen Fortschritt zu verfolgen.")
        .accessibilityIdentifier("history.emptyState")
    }

    private func errorStateView(message: String) -> some View {
        VStack(spacing: theme.spacing.md) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.errorFeedback.color)
                .accessibilityHidden(true)

            Text("Fehler beim Laden")
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary.color)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.textSecondary.color)
                .padding(.horizontal, theme.spacing.lg)

            Button(action: loadRecords) {
                Text("Erneut versuchen")
                    .font(.body.weight(.semibold))
                    .foregroundColor(theme.colors.onAccent.color)
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.vertical, theme.spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .fill(theme.colors.errorFeedback.color)
                    )
            }
            .buttonStyle(TactileButtonStyle())
            .accessibilityIdentifier("history.retryButton")

            Spacer()
        }
        .frame(maxWidth: theme.layout.maxContentWidthiPad)
        .padding(theme.spacing.lg)
        .accessibilityIdentifier("history.errorState")
    }

    private var recordsListView: some View {
        ScrollView {
            VStack(spacing: theme.spacing.md) {
                // Header with Count & Clear Action
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verlauf (\(records.count))")
                            .font(.title2.weight(.bold))
                            .foregroundColor(theme.colors.textPrimary.color)
                        Text("Max. 50 Einträge (FIFO)")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary.color)
                    }

                    Spacer()

                    Button(action: { showClearConfirmation = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.subheadline)
                            Text("Löschen")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(theme.colors.errorFeedback.color)
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                                .stroke(theme.colors.errorFeedback.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(TactileButtonStyle())
                    .accessibilityLabel("Gesamten Verlauf löschen")
                    .accessibilityIdentifier("history.clearButton")
                }
                .padding(.horizontal, theme.spacing.xs)
                .padding(.top, theme.spacing.sm)

                // Cards List
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    let previousRecord = HistoryComparisonService.findPreviousCompatibleRecord(
                        for: record,
                        in: records
                    )
                    let comparison = previousRecord.flatMap {
                        HistoryComparisonService.compare(current: record, previous: $0)
                    }

                    historyCard(
                        record: record,
                        index: index,
                        comparison: comparison
                    )
                }
            }
            .frame(maxWidth: theme.layout.maxContentWidthiPad)
            .padding(theme.spacing.md)
        }
    }

    private func historyCard(
        record: AssessmentRecord,
        index: Int,
        comparison: AssessmentComparison?
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Top Row: Date, Duration and Score
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.dateFormatter.string(from: record.completedAt))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.colors.textPrimary.color)

                    Text(formatDuration(record.durationSeconds))
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary.color)
                }

                Spacer()

                // Overall Score Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f %%", record.overallScore))
                        .font(.title3.weight(.heavy))
                        .foregroundColor(theme.colors.textPrimary.color)

                    if let comparison = comparison {
                        deltaBadge(comparison.overallDeltaPercentagePoints, formatted: comparison.formattedOverallDelta)
                    }
                }
            }

            Divider()
                .padding(.vertical, 2)

            // Middle Row: Dominant Archetype
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: record.archetype.badgeSymbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(theme.colorToken(forDimension: record.archetype.dominantDimensionId).color)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(theme.colorToken(forDimension: record.archetype.dominantDimensionId).color.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text("Dominanter Archetyp")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(theme.colors.textSecondary.color)
                    Text(record.archetype.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(theme.colors.textPrimary.color)
                }
            }

            // Dimension Mini-Bar Breakdown
            VStack(spacing: 6) {
                ForEach(AssessmentDimension.standardDimensions) { dimension in
                    let score = record.dimensionScores[dimension.id] ?? 0.0
                    let dimDelta = comparison?.dimensionComparisons.first(where: { $0.dimensionId == dimension.id })

                    HStack(spacing: theme.spacing.xs) {
                        Text(dimension.name)
                            .font(.caption2)
                            .foregroundColor(theme.colors.textSecondary.color)
                            .frame(width: 100, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.colors.textSecondary.color.opacity(0.12))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.colorToken(forDimension: dimension.id).color)
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(score / 100.0))), height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text(String(format: "%.0f%%", score))
                            .font(.caption2.weight(.medium))
                            .foregroundColor(theme.colors.textPrimary.color)
                            .frame(width: 36, alignment: .trailing)

                        if let dimDelta = dimDelta {
                            Text(dimDelta.formattedDelta)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(colorForDelta(dimDelta.deltaPercentagePoints))
                                .frame(width: 52, alignment: .trailing)
                        } else {
                            Text("–")
                                .font(.caption2)
                                .foregroundColor(theme.colors.textSecondary.color.opacity(0.5))
                                .frame(width: 52, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .fill(theme.colors.surfaceCard.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(theme.colors.textSecondary.color.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary(record: record, comparison: comparison))
        .accessibilityIdentifier("history.recordCard.\(index)")
    }

    private func deltaBadge(_ delta: Double, formatted: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: deltaIcon(delta))
                .font(.system(size: 9, weight: .bold))
            Text(formatted)
                .font(.caption2.weight(.bold))
        }
        .foregroundColor(colorForDelta(delta))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(colorForDelta(delta).opacity(0.12))
        )
        .accessibilityLabel("Veränderung: \(formatted)")
    }

    private func deltaIcon(_ delta: Double) -> String {
        if delta > 0.05 {
            return "arrow.up.right"
        } else if delta < -0.05 {
            return "arrow.down.right"
        } else {
            return "minus"
        }
    }

    private func colorForDelta(_ delta: Double) -> Color {
        if delta > 0.05 {
            return theme.colors.successFeedback.color
        } else if delta < -0.05 {
            return theme.colors.errorFeedback.color
        } else {
            return theme.colors.textSecondary.color
        }
    }

    private func formatDuration(_ durationSeconds: Double) -> String {
        let totalSeconds = Int(durationSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes) Min. \(seconds) Sek."
        } else {
            return "\(seconds) Sek."
        }
    }

    private func accessibilitySummary(record: AssessmentRecord, comparison: AssessmentComparison?) -> String {
        var summary = "Assessment vom \(Self.dateFormatter.string(from: record.completedAt)), Gesamtpunktzahl \(String(format: "%.1f", record.overallScore)) Prozent, Dominanter Archetyp \(record.archetype.title)."
        if let comparison = comparison {
            summary += " Zeitlicher Vergleich zum Vorlauf: \(comparison.formattedOverallDelta)."
        }
        return summary
    }

    // MARK: - Actions

    public func loadRecords() {
        do {
            records = try historyStore.loadHistory()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearAllHistory() {
        do {
            try historyStore.clearHistory()
            records.removeAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
