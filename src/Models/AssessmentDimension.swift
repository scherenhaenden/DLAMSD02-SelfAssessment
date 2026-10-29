import Foundation

/// Represents a distinct technical or methodological domain evaluated in the self-assessment.
public struct AssessmentDimension: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let summary: String
    public let iconName: String
    public let targetWeight: Double

    public init(
        id: String,
        name: String,
        summary: String,
        iconName: String,
        targetWeight: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.iconName = iconName
        self.targetWeight = targetWeight
    }

    public static let standardDimensions: [AssessmentDimension] = [
        AssessmentDimension(
            id: "architecture",
            name: "Software Architecture & System Design",
            summary: "Modular design, clean separation of concerns, architectural patterns and scalability.",
            iconName: "square.grid.3x3.topleft.filled",
            targetWeight: 1.0
        ),
        AssessmentDimension(
            id: "platform",
            name: "Swift & Apple Platform Engineering",
            summary: "Idiomatic Swift, memory safety, SwiftUI declarative state, Combine and modern concurrency.",
            iconName: "apple.logo",
            targetWeight: 1.0
        ),
        AssessmentDimension(
            id: "quality",
            name: "Quality Assurance & Verification",
            summary: "Automated unit testing, XCUITest, boundary analysis, coverage standards and defensive programming.",
            iconName: "checkmark.shield.fill",
            targetWeight: 1.0
        ),
        AssessmentDimension(
            id: "agile",
            name: "Agile Practices & Collaboration",
            summary: "Iterative sprints, conventional commits, peer reviews, CI/CD pipelines and academic documentation.",
            iconName: "person.2.badge.gearshape.fill",
            targetWeight: 1.0
        )
    ]
}
