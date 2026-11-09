import SwiftUI

/// An accessible, state-explicit Likert slider card displaying scale anchors, step values, and interactive slider control.
public struct LikertSliderCard: View {
    @Environment(\.appTheme) private var theme

    public let value: Double
    public let minVal: Double
    public let maxVal: Double
    public let step: Double
    public let minLabel: String
    public let maxLabel: String
    public let dimensionId: String?
    public let onValueChange: (Double) -> Void

    public init(
        value: Double,
        minVal: Double = 1.0,
        maxVal: Double = 5.0,
        step: Double = 1.0,
        minLabel: String? = nil,
        maxLabel: String? = nil,
        dimensionId: String? = nil,
        onValueChange: @escaping (Double) -> Void
    ) {
        self.value = value
        self.minVal = minVal
        self.maxVal = maxVal
        self.step = step > 0 ? step : 1.0
        self.minLabel = minLabel ?? "Stimme überhaupt nicht zu"
        self.maxLabel = maxLabel ?? "Stimme voll und ganz zu"
        self.dimensionId = dimensionId
        self.onValueChange = onValueChange
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Current value indicator callout
            HStack {
                Text(verbalAnchor)
                    .font(.headline)
                    .foregroundColor(theme.colors.textPrimary.color)
                    .accessibilityIdentifier("likertSlider.verbalAnchor")
                Spacer()
                Text(formattedScore)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.small, style: .continuous)
                            .fill(accentColor.opacity(0.12))
                    )
                    .accessibilityIdentifier("likertSlider.scoreBadge")
            }

            // Slider control: use discrete stepping only if step count fits comfortably in memory/integer space,
            // otherwise use continuous range with manual snapping in binding to prevent SwiftUI internal Int overflow.
            if (maxVal - minVal) / step <= 1000 {
                Slider(
                    value: Binding(
                        get: { value },
                        set: { newValue in
                            let stepped = (round((newValue - minVal) / step) * step) + minVal
                            let clamped = min(maxVal, max(minVal, stepped))
                            onValueChange(clamped)
                        }
                    ),
                    in: minVal...maxVal,
                    step: step
                )
                .tint(accentColor)
                .accessibilityIdentifier("likertSlider")
                .accessibilityLabel("Einschätzung auf einer Skala von \(safeNumberString(minVal)) bis \(safeNumberString(maxVal))")
                .accessibilityValue("\(formattedScore): \(verbalAnchor)")
                .accessibilityHint("Streiche mit einem Finger nach oben oder unten, um den Wert anzupassen.")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        let next = min(maxVal, value + step)
                        onValueChange(next)
                    case .decrement:
                        let prev = max(minVal, value - step)
                        onValueChange(prev)
                    @unknown default:
                        break
                    }
                }
            } else {
                Slider(
                    value: Binding(
                        get: { value },
                        set: { newValue in
                            let stepped = (round((newValue - minVal) / step) * step) + minVal
                            let clamped = min(maxVal, max(minVal, stepped))
                            onValueChange(clamped)
                        }
                    ),
                    in: minVal...maxVal
                )
                .tint(accentColor)
                .accessibilityIdentifier("likertSlider")
                .accessibilityLabel("Einschätzung auf einer Skala von \(safeNumberString(minVal)) bis \(safeNumberString(maxVal))")
                .accessibilityValue("\(formattedScore): \(verbalAnchor)")
                .accessibilityHint("Streiche mit einem Finger nach oben oder unten, um den Wert anzupassen.")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        let next = min(maxVal, value + step)
                        onValueChange(next)
                    case .decrement:
                        let prev = max(minVal, value - step)
                        onValueChange(prev)
                    @unknown default:
                        break
                    }
                }
            }

            // Extreme scale anchors
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(safeNumberString(minVal))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textSecondary.color)
                    Text(minLabel)
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(safeNumberString(maxVal))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textSecondary.color)
                    Text(maxLabel)
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary.color)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium, style: .continuous)
                .fill(theme.colors.surfaceCard.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium, style: .continuous)
                .strokeBorder(theme.colors.textSecondary.color.opacity(0.15), lineWidth: 1)
        )
    }

    private func safeNumberString(_ val: Double) -> String {
        guard val.isFinite else { return "0" }
        // Keep within safe integer range (+/- 1e15) to guarantee exact Double integer representation
        // and avoid IEEE 754 rounding into Int.max + 1 overflow.
        if val >= -1e15 && val <= 1e15 && val.truncatingRemainder(dividingBy: 1.0) == 0.0 {
            return "\(Int64(val))"
        }
        return String(format: "%.1f", val)
    }

    private var formattedScore: String {
        if step == 1.0 && value.truncatingRemainder(dividingBy: 1.0) == 0.0 {
            return "\(safeNumberString(value)) / \(safeNumberString(maxVal))"
        } else {
            return String(format: "%.1f / %.1f", value, maxVal)
        }
    }

    private var verbalAnchor: String {
        let normalizedRatio = (value - minVal) / (maxVal - minVal)
        if normalizedRatio <= 0.15 {
            return "Sehr niedrig"
        } else if normalizedRatio <= 0.40 {
            return "Eher gering"
        } else if normalizedRatio <= 0.60 {
            return "Mittelmäßig"
        } else if normalizedRatio <= 0.85 {
            return "Eher hoch"
        } else {
            return "Sehr ausgeprägt"
        }
    }

    private var accentColor: Color {
        if let dim = dimensionId {
            return theme.colorToken(forDimension: dim).color
        }
        return theme.colors.textPrimary.color
    }
}
