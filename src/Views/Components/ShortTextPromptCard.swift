import SwiftUI

/// An accessible, state-explicit short-text reflection card with live character counter and length milestone indicators.
public struct ShortTextPromptCard: View {
    @Environment(\.appTheme) private var theme

    public let text: String
    public let minCharacters: Int
    public let maxCharacters: Int
    public let placeholder: String
    public let dimensionId: String?
    public let onTextChange: (String) -> Void

    public init(
        text: String,
        minCharacters: Int = 15,
        maxCharacters: Int = 350,
        placeholder: String? = nil,
        dimensionId: String? = nil,
        onTextChange: @escaping (String) -> Void
    ) {
        self.text = text
        self.minCharacters = minCharacters
        self.maxCharacters = maxCharacters
        self.placeholder = placeholder ?? "Beschreibe hier deine konkreten Praxiserfahrungen..."
        self.dimensionId = dimensionId
        self.onTextChange = onTextChange
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Text input area
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary.color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                #if os(macOS)
                TextEditor(text: Binding(
                    get: { text },
                    set: { onTextChange($0) }
                ))
                .font(.body)
                .frame(minHeight: 110)
                .scrollContentBackground(.hidden)
                .accessibilityIdentifier("shortTextEditor")
                .accessibilityLabel(placeholder)
                .accessibilityHint("Eingabefeld für deinen Reflexionstext.")
                #else
                TextEditor(text: Binding(
                    get: { text },
                    set: { onTextChange($0) }
                ))
                .font(.body)
                .frame(minHeight: 110)
                .accessibilityIdentifier("shortTextEditor")
                .accessibilityLabel(placeholder)
                .accessibilityHint("Eingabefeld für deinen Reflexionstext.")
                #endif
            }
            .padding(theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium, style: .continuous)
                    .fill(theme.colors.surfaceCard.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium, style: .continuous)
                    .strokeBorder(borderStrokeColor, lineWidth: isFocusedOrValid ? 1.5 : 1.0)
            )

            // Status bar: Character count and length feedback
            HStack {
                // Milestone badge
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: statusIcon)
                        .font(.caption2)
                    Text(statusMessage)
                        .font(.caption)
                }
                .foregroundColor(statusColor)

                Spacer()

                // Character counter
                Text("\(trimmedCount) / \(maxCharacters)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(counterColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Reflexionsstatus: \(trimmedCount) von maximal \(maxCharacters) Zeichen. \(statusMessage)")
            .accessibilityValue("\(trimmedCount) Zeichen")
        }
    }

    private var trimmedCount: Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var isTooShort: Bool {
        trimmedCount < minCharacters
    }

    private var isTooLong: Bool {
        trimmedCount > maxCharacters
    }

    private var isFocusedOrValid: Bool {
        !isTooShort && !isTooLong
    }

    private var statusIcon: String {
        if isTooLong {
            return "exclamationmark.triangle.fill"
        } else if isTooShort {
            return "info.circle"
        } else {
            return "checkmark.circle.fill"
        }
    }

    private var statusMessage: String {
        if isTooLong {
            let over = trimmedCount - maxCharacters
            return "Zu lang: \(over) Zeichen über Maximum"
        } else if isTooShort {
            let remaining = minCharacters - trimmedCount
            return "Noch \(remaining) Zeichen bis zum Mindestumfang"
        } else {
            return "Mindestumfang erfüllt"
        }
    }

    private var statusColor: Color {
        if isTooLong {
            return theme.colors.errorFeedback.color
        } else if isTooShort {
            return theme.colors.textSecondary.color
        } else {
            return theme.colors.successFeedback.color
        }
    }

    private var counterColor: Color {
        if isTooLong {
            return theme.colors.errorFeedback.color
        } else {
            return theme.colors.textSecondary.color
        }
    }

    private var borderStrokeColor: Color {
        if isTooLong {
            return theme.colors.errorFeedback.color
        } else if !isTooShort {
            return accentColor
        } else {
            return theme.colors.textSecondary.color.opacity(0.2)
        }
    }

    private var accentColor: Color {
        if let dim = dimensionId {
            return theme.colorToken(forDimension: dim).color
        }
        return theme.colors.textPrimary.color
    }
}
