import SwiftUI

// MARK: - Token Substructures (Value Types)

/// Grid spacing values in points.
public struct SpacingTokens: Sendable, Hashable {
    public let xs: CGFloat
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let xl: CGFloat

    public init(
        xs: CGFloat = 4.0,
        sm: CGFloat = 8.0,
        md: CGFloat = 16.0,
        lg: CGFloat = 24.0,
        xl: CGFloat = 32.0
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
    }
}

/// Continuous corner radii for rounded surfaces.
public struct CornerRadiusTokens: Sendable, Hashable {
    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat

    public init(
        small: CGFloat = 8.0,
        medium: CGFloat = 14.0,
        large: CGFloat = 20.0
    ) {
        self.small = small
        self.medium = medium
        self.large = large
    }
}

/// Layout and ergonomics specifications.
public struct LayoutTokens: Sendable, Hashable {
    public let maxContentWidthiPad: CGFloat
    public let minTouchTargetSize: CGFloat
    public let primaryButtonHeight: CGFloat

    public init(
        maxContentWidthiPad: CGFloat = 640.0,
        minTouchTargetSize: CGFloat = 44.0,
        primaryButtonHeight: CGFloat = 56.0
    ) {
        self.maxContentWidthiPad = maxContentWidthiPad
        self.minTouchTargetSize = minTouchTargetSize
        self.primaryButtonHeight = primaryButtonHeight
    }
}

/// Semantic surface and feedback colors.
public struct ColorTokens: Sendable, Hashable {
    public let background: AdaptiveColorToken
    public let surfaceCard: AdaptiveColorToken
    public let textPrimary: AdaptiveColorToken
    public let textSecondary: AdaptiveColorToken
    public let successFeedback: AdaptiveColorToken
    public let warningFeedback: AdaptiveColorToken
    public let errorFeedback: AdaptiveColorToken
    public let onAccent: AdaptiveColorToken

    public init(
        background: AdaptiveColorToken = AdaptiveColorToken(
            lightRGB: AppRGBColor(hex: 0xF8FAFC),
            darkRGB: AppRGBColor(hex: 0x090D16)
        ),
        surfaceCard: AdaptiveColorToken = AdaptiveColorToken(
            lightRGB: AppRGBColor(hex: 0xFFFFFF),
            darkRGB: AppRGBColor(hex: 0x1E293B)
        ),
        textPrimary: AdaptiveColorToken = AdaptiveColorToken(
            lightRGB: AppRGBColor(hex: 0x0F172A),
            darkRGB: AppRGBColor(hex: 0xF8FAFC)
        ),
        textSecondary: AdaptiveColorToken = AdaptiveColorToken(
            lightRGB: AppRGBColor(hex: 0x475569),
            darkRGB: AppRGBColor(hex: 0x94A3B8)
        ),
        successFeedback: AdaptiveColorToken = AdaptiveColorToken(
            lightRGB: AppRGBColor(hex: 0x14532D),
            darkRGB: AppRGBColor(hex: 0x4ADE80)
        ),
        warningFeedback: AdaptiveColorToken = AdaptiveColorToken(
            lightRGB: AppRGBColor(hex: 0x854D0E),
            darkRGB: AppRGBColor(hex: 0xFACC15)
        ),
        errorFeedback: AdaptiveColorToken = AdaptiveColorToken(
            lightRGB: AppRGBColor(hex: 0x991B1B),
            darkRGB: AppRGBColor(hex: 0xF87171)
        ),
        onAccent: AdaptiveColorToken = AdaptiveColorToken(
            lightRGB: AppRGBColor(hex: 0xFFFFFF),
            darkRGB: AppRGBColor(hex: 0x090D16)
        )
    ) {
        self.background = background
        self.surfaceCard = surfaceCard
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.successFeedback = successFeedback
        self.warningFeedback = warningFeedback
        self.errorFeedback = errorFeedback
        self.onAccent = onAccent
    }
}

// MARK: - Protocol-Oriented Theme Contract

/// Defines an injectable design system theme contract.
public protocol AppThemeProtocol: Sendable {
    var spacing: SpacingTokens { get }
    var cornerRadius: CornerRadiusTokens { get }
    var layout: LayoutTokens { get }
    var colors: ColorTokens { get }

    func colorToken(forDimension id: String) -> AdaptiveColorToken
}

// MARK: - Concrete Injectable Theme Implementation

/// Default concrete implementation of the application design theme.
public struct AppTheme: AppThemeProtocol, Sendable {
    public let spacing: SpacingTokens
    public let cornerRadius: CornerRadiusTokens
    public let layout: LayoutTokens
    public let colors: ColorTokens

    private let dimensionColors: [String: AdaptiveColorToken]

    public init(
        spacing: SpacingTokens = SpacingTokens(),
        cornerRadius: CornerRadiusTokens = CornerRadiusTokens(),
        layout: LayoutTokens = LayoutTokens(),
        colors: ColorTokens = ColorTokens(),
        dimensionColors: [String: AdaptiveColorToken]? = nil
    ) {
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.layout = layout
        self.colors = colors

        if let customDimensions = dimensionColors {
            self.dimensionColors = customDimensions
        } else {
            self.dimensionColors = [
                "architecture": AdaptiveColorToken(
                    lightRGB: AppRGBColor(hex: 0x1E3A8A),
                    darkRGB: AppRGBColor(hex: 0x38BDF8)
                ),
                "platform": AdaptiveColorToken(
                    lightRGB: AppRGBColor(hex: 0x581C87),
                    darkRGB: AppRGBColor(hex: 0xC084FC)
                ),
                "quality": AdaptiveColorToken(
                    lightRGB: AppRGBColor(hex: 0x14532D),
                    darkRGB: AppRGBColor(hex: 0x4ADE80)
                ),
                "agile": AdaptiveColorToken(
                    lightRGB: AppRGBColor(hex: 0x9A3412),
                    darkRGB: AppRGBColor(hex: 0xFBBF24)
                )
            ]
        }
    }

    public func colorToken(forDimension id: String) -> AdaptiveColorToken {
        return dimensionColors[id] ?? colors.textSecondary
    }

    /// Standard default instance for dependency injection.
    public static let standard = AppTheme()
}

// MARK: - SwiftUI Environment Integration

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppThemeProtocol = AppTheme.standard
}

public extension EnvironmentValues {
    var appTheme: AppThemeProtocol {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

public extension View {
    /// Injects an injectable theme instance down the SwiftUI view hierarchy.
    func appTheme(_ theme: AppThemeProtocol) -> some View {
        environment(\.appTheme, theme)
    }
}
