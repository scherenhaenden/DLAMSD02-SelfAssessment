import Foundation

/// Represents a diagnostic archetype or competency profile resulting from the assessment.
public struct ArchetypeProfile: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let dominantDimensionId: String
    public let description: String
    public let strengths: [String]
    public let growthOpportunities: [String]
    public let badgeSymbol: String

    public init(
        id: String,
        title: String,
        subtitle: String,
        dominantDimensionId: String,
        description: String,
        strengths: [String],
        growthOpportunities: [String],
        badgeSymbol: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.dominantDimensionId = dominantDimensionId
        self.description = description
        self.strengths = strengths
        self.growthOpportunities = growthOpportunities
        self.badgeSymbol = badgeSymbol
    }

    public static let standardArchetypes: [ArchetypeProfile] = [
        ArchetypeProfile(
            id: "system-architect",
            title: "Systems & Software Architect",
            subtitle: "Dominante Dimension: Software Architecture & System Design",
            dominantDimensionId: "architecture",
            description: "Starke Ausprägung in modularem Denken, Entwurfsmustern und sauberer Schichtentrennung. Du planst Systeme vorausschauend und nachhaltig.",
            strengths: [
                "Entwurf robuster Schichten- und Modul-Architekturen",
                "Fundierte Abwägung von Trade-Offs (ADR-Methodik)",
                "Minimierung von zyklischen Abhängigkeiten"
            ],
            growthOpportunities: [
                "Erhöhung der automatisierten Testabdeckung im UI-Layer",
                "Schnellere Prototyping-Iterationen im agilen Feedback"
            ],
            badgeSymbol: "building.columns.fill"
        ),
        ArchetypeProfile(
            id: "platform-craftsperson",
            title: "Apple Platform Craftsperson",
            subtitle: "Dominante Dimension: Swift & Platform Engineering",
            dominantDimensionId: "platform",
            description: "Exzellente Beherrschung des nativen Apple-Ökosystems, idiomatischem Swift, modernen Concurrency-Mustern und deklarativem SwiftUI.",
            strengths: [
                "Idiomatischer Swift-Code unter Einhaltung der Apple API Guidelines",
                "Reaktives State-Management mit SwiftUI und Combine",
                "Plattformnahe Nutzung von UIKit-Bridges und System-APIs"
            ],
            growthOpportunities: [
                "Systematische Dokumentation von Architekturentscheidungen",
                "Formalisierung von Lastenheft- und V-Modell-Prozessen"
            ],
            badgeSymbol: "apple.logo"
        ),
        ArchetypeProfile(
            id: "quality-champion",
            title: "Quality & Verification Champion",
            subtitle: "Dominante Dimension: Quality Assurance & Verification",
            dominantDimensionId: "quality",
            description: "Strikter Fokus auf Verifizierbarkeit, deterministische Testsuiten, defensive Programmierung und lückenlose Code-Coverage.",
            strengths: [
                "Umfassende XCTest- und XCUITest-Automatisierung",
                "Grenzfallanalysen und defensive Invariantenprüfung",
                "llvm-cov Reporting und CI/CD-Pipelines"
            ],
            growthOpportunities: [
                "Fokus auf frühe UI-Exploration vor Test-Erstarrung",
                "Flexiblere Anpassung an sich ändernde Produktanforderungen"
            ],
            badgeSymbol: "checkmark.seal.fill"
        ),
        ArchetypeProfile(
            id: "agile-orchestrator",
            title: "Agile Engineering Orchestrator",
            subtitle: "Dominante Dimension: Agile Practices & Collaboration",
            dominantDimensionId: "agile",
            description: "Hohe Kompetenz in iterativer Sprint-Steuerung, transparenter Versionsverwaltung, akademischer Dokumentation und Team-Synergien.",
            strengths: [
                "Klare Definition of Done und Sprint-Roadmaps",
                "Saubere Git-Governance und konventionelle Commits",
                "Wissenschaftliche Nachvollziehbarkeit und Dokumentation"
            ],
            growthOpportunities: [
                "Tiefere Vertiefung in plattformspezifische Compiler-Optimierungen",
                "Erweiterung hardwarenaher Profiling-Kenntnisse (Instruments)"
            ],
            badgeSymbol: "person.3.sequence.fill"
        )
    ]
}
