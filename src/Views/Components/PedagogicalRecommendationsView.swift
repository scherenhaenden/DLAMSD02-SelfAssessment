import SwiftUI

/// Component presenting personalized pedagogical learning recommendations derived from assessment dimension scores.
public struct PedagogicalRecommendationsView: View {
    public let dimensionScores: [String: Double]
    public let theme: any AppThemeProtocol

    /// Deterministic canonical dimension precedence convention for resolving ties when dimension scores are identical:
    /// Architecture -> Platform -> Quality -> Agile.
    public static let canonicalDimensionPrecedence: [String: Int] = [
        "architecture": 0,
        "platform": 1,
        "quality": 2,
        "agile": 3
    ]

    public init(
        dimensionScores: [String: Double],
        theme: any AppThemeProtocol = AppTheme()
    ) {
        self.dimensionScores = dimensionScores
        self.theme = theme
    }

    public struct RecommendationItem: Identifiable, Equatable {
        public let id: String
        public let dimensionId: String
        public let dimensionTitle: String
        public let iconSystemName: String
        public let recommendation: String
        public let priority: String
    }

    public var recommendations: [RecommendationItem] {
        var items: [RecommendationItem] = []

        // Sort dimensions by score ascending (lowest score gets highest priority)
        // Deterministic tie-breaking with strict weak ordering (transitive total order):
        // Tier 1: Quantized numerical score ascending (binned to 0.001 to guarantee mathematical transitivity and eliminate non-transitive epsilon cycles)
        // Tier 2: Canonical dimension precedence convention (architecture < platform < quality < agile)
        // Tier 3: Lexicographical dimension ID fallback
        let sortedDimensions = dimensionScores.sorted { lhs, rhs in
            let lhsQuantized = (lhs.value * 1000.0).rounded()
            let rhsQuantized = (rhs.value * 1000.0).rounded()
            if lhsQuantized != rhsQuantized {
                return lhsQuantized < rhsQuantized
            }
            let lhsOrder = Self.canonicalDimensionPrecedence[lhs.key] ?? 99
            let rhsOrder = Self.canonicalDimensionPrecedence[rhs.key] ?? 99
            if lhsOrder != rhsOrder {
                return lhsOrder < rhsOrder
            }
            return lhs.key < rhs.key
        }

        for (dimId, score) in sortedDimensions {
            let priority = score < 60.0 ? "Hohe Priorität" : (score < 80.0 ? "Empfohlen" : "Vertiefung")
            switch dimId {
            case "architecture":
                items.append(
                    RecommendationItem(
                        id: "rec-\(dimId)",
                        dimensionId: dimId,
                        dimensionTitle: "Software Architecture",
                        iconSystemName: "building.columns.fill",
                        recommendation: "Vertiefe modulare Schichtentrennung, lose Kopplung via Swift Protocols und dokumentiere Entwurfsentscheidungen systematisch mit Architecture Decision Records (ADRs).",
                        priority: priority
                    )
                )
            case "platform":
                items.append(
                    RecommendationItem(
                        id: "rec-\(dimId)",
                        dimensionId: dimId,
                        dimensionTitle: "Swift & Apple Platform",
                        iconSystemName: "apple.logo",
                        recommendation: "Stärke deine Kenntnisse in modernem Swift (Sendable, Concurrency, Actor-Modell), deklarativem SwiftUI State-Management und Apple Human Interface Guidelines.",
                        priority: priority
                    )
                )
            case "quality":
                items.append(
                    RecommendationItem(
                        id: "rec-\(dimId)",
                        dimensionId: dimId,
                        dimensionTitle: "Quality & Verification",
                        iconSystemName: "checkmark.seal.fill",
                        recommendation: "Etabliere lückenlose automatisierte Testsuiten (Unit-, Integrations- und XCUITests), Thread Sanitizer Prüfungen und überprüfe Code-Coverage mit llvm-cov.",
                        priority: priority
                    )
                )
            case "agile":
                items.append(
                    RecommendationItem(
                        id: "rec-\(dimId)",
                        dimensionId: dimId,
                        dimensionTitle: "Agile Engineering",
                        iconSystemName: "arrow.triangle.2.circlepath",
                        recommendation: "Optimiere agile Sprint-Iterationen, halte konsequente Git-Governance mit Conventional Commits ein und dokumentiere Entwicklungsschritte wissenschaftlich nachvollziehbar.",
                        priority: priority
                    )
                )
            default:
                // Generic didactical fallback for dynamically imported custom dimensions (Sprint 9 limitation mitigation)
                items.append(
                    RecommendationItem(
                        id: "rec-\(dimId)",
                        dimensionId: dimId,
                        dimensionTitle: dimId.capitalized,
                        iconSystemName: "star.fill",
                        recommendation: "Vertiefe die theoretischen und praktischen Grundlagen der Domäne \(dimId.capitalized) durch gezielte Übungseinheiten und Literaturstudium.",
                        priority: priority
                    )
                )
            }
        }

        return items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "graduationcap.fill")
                    .font(.headline)
                    .foregroundColor(theme.colorToken(forDimension: "architecture").color)

                Text("Didaktische Handlungsempfehlungen")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary.color)
            }

            VStack(spacing: theme.spacing.sm) {
                ForEach(recommendations.prefix(3)) { item in
                    let dimColor = theme.colorToken(forDimension: item.dimensionId).color

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        HStack {
                            Image(systemName: item.iconSystemName)
                                .font(.caption)
                                .foregroundColor(dimColor)

                            Text(item.dimensionTitle)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(dimColor)

                            Spacer()

                            Text(item.priority)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(dimColor.opacity(0.12))
                                )
                                .foregroundColor(dimColor)
                        }

                        Text(item.recommendation)
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary.color)
                            .lineSpacing(2)
                    }
                    .padding(theme.spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .fill(theme.colors.surfaceCard.color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .stroke(theme.colors.textSecondary.color.opacity(0.12), lineWidth: 1)
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pedagogicalRecommendations")
    }
}
