import Foundation

/// Represents the comparative score delta between two assessments for a specific dimension.
public struct DimensionComparison: Equatable, Sendable, Identifiable {
    public var id: String { dimensionId }
    public let dimensionId: String
    public let currentScore: Double?
    public let previousScore: Double?
    /// Difference in percentage points (`currentScore - previousScore`), or `nil` if not measured in both records.
    public let deltaPercentagePoints: Double?

    public init(
        dimensionId: String,
        currentScore: Double?,
        previousScore: Double?
    ) {
        self.dimensionId = dimensionId
        self.currentScore = currentScore
        self.previousScore = previousScore
        if let cur = currentScore, let prev = previousScore {
            self.deltaPercentagePoints = cur - prev
        } else {
            self.deltaPercentagePoints = nil
        }
    }

    public var isComparable: Bool {
        deltaPercentagePoints != nil
    }

    public var formattedDelta: String {
        guard let delta = deltaPercentagePoints else {
            return "–"
        }
        return HistoryComparisonService.formatPercentagePoints(delta)
    }
}

/// Represents the temporal progress comparison between two compatible assessment records.
public struct AssessmentComparison: Equatable, Sendable {
    public let currentRecordId: UUID
    public let previousRecordId: UUID
    public let catalogId: String
    public let currentOverallScore: Double
    public let previousOverallScore: Double
    /// Difference in overall percentage points (`currentOverallScore - previousOverallScore`).
    public let overallDeltaPercentagePoints: Double
    public let dimensionComparisons: [DimensionComparison]

    public init(
        currentRecordId: UUID,
        previousRecordId: UUID,
        catalogId: String,
        currentOverallScore: Double,
        previousOverallScore: Double,
        dimensionComparisons: [DimensionComparison]
    ) {
        self.currentRecordId = currentRecordId
        self.previousRecordId = previousRecordId
        self.catalogId = catalogId
        self.currentOverallScore = currentOverallScore
        self.previousOverallScore = previousOverallScore
        self.overallDeltaPercentagePoints = currentOverallScore - previousOverallScore
        self.dimensionComparisons = dimensionComparisons
    }

    public var formattedOverallDelta: String {
        HistoryComparisonService.formatPercentagePoints(overallDeltaPercentagePoints)
    }
}

/// Domain service for calculating delta comparisons in percentage points (pp) between assessment runs.
public enum HistoryComparisonService {
    /// Formats a delta value into standard percentage points notation: `+5.0 pp`, `-2.5 pp`, `0.0 pp`.
    public static func formatPercentagePoints(_ delta: Double) -> String {
        if abs(delta) < 0.05 {
            return "0.0 pp"
        }
        let sign = delta > 0 ? "+" : ""
        return String(format: "%@%.1f pp", sign, delta)
    }

    /// Verifies catalog compatibility based on SemVer major versioning.
    /// Catalogs with different major versions are treated as distinct instruments.
    public static func areVersionsCompatible(lhs: String, rhs: String) -> Bool {
        let lhsMajor = lhs.split(separator: ".").first ?? Substring(lhs)
        let rhsMajor = rhs.split(separator: ".").first ?? Substring(rhs)
        return lhsMajor == rhsMajor
    }

    /// Determines whether a candidate record is strictly older than the reference record
    /// under the total chronological ordering (completedAt descending, tie-broken by id.uuidString).
    public static func isRecordStrictlyOlder(_ candidate: AssessmentRecord, than current: AssessmentRecord) -> Bool {
        if candidate.completedAt != current.completedAt {
            return candidate.completedAt < current.completedAt
        }
        return candidate.id.uuidString < current.id.uuidString
    }

    /// Compares two assessment records if they share the same catalog identifier and compatible schema version.
    /// Returns `nil` if catalogs are incompatible (`lhs.catalogId != rhs.catalogId` or incompatible versions).
    public static func compare(
        current: AssessmentRecord,
        previous: AssessmentRecord
    ) -> AssessmentComparison? {
        guard current.catalogId == previous.catalogId else {
            return nil
        }
        guard areVersionsCompatible(lhs: current.catalogVersion, rhs: previous.catalogVersion) else {
            return nil
        }

        // Collect all dimension IDs from both records deterministically
        var allDimensionIds = Set(current.dimensionScores.keys)
        allDimensionIds.formUnion(previous.dimensionScores.keys)
        let sortedDimensionIds = Array(allDimensionIds).sorted()

        let dimensionComparisons = sortedDimensionIds.map { dimId in
            let curScore = current.dimensionScores[dimId]
            let prevScore = previous.dimensionScores[dimId]
            return DimensionComparison(
                dimensionId: dimId,
                currentScore: curScore,
                previousScore: prevScore
            )
        }

        return AssessmentComparison(
            currentRecordId: current.id,
            previousRecordId: previous.id,
            catalogId: current.catalogId,
            currentOverallScore: current.overallScore,
            previousOverallScore: previous.overallScore,
            dimensionComparisons: dimensionComparisons
        )
    }

    /// Finds the chronologically immediately preceding compatible record in an ordered history array.
    /// Strictly guarantees acyclic, asymmetric comparison even in the presence of identical completedAt timestamps.
    public static func findPreviousCompatibleRecord(
        for current: AssessmentRecord,
        in history: [AssessmentRecord]
    ) -> AssessmentRecord? {
        return history.first { candidate in
            candidate.id != current.id &&
            candidate.catalogId == current.catalogId &&
            areVersionsCompatible(lhs: candidate.catalogVersion, rhs: current.catalogVersion) &&
            isRecordStrictlyOlder(candidate, than: current)
        }
    }
}
