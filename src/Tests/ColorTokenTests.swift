import XCTest
@testable import AssessYourselfCore

final class ColorTokenTests: XCTestCase {
    var theme: AppThemeProtocol!

    override func setUp() {
        super.setUp()
        theme = AppTheme.standard
    }

    override func tearDown() {
        theme = nil
        super.tearDown()
    }

    // MARK: - WCAG 2.1 Relative Luminance & Contrast Calculation Helpers

    private func relativeLuminance(rgb: AppRGBColor) -> Double {
        func channelLinear(_ c: Double) -> Double {
            return c <= 0.04045 ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
        }
        let rLin = channelLinear(rgb.r)
        let gLin = channelLinear(rgb.g)
        let bLin = channelLinear(rgb.b)
        return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin
    }

    private func contrastRatio(l1: Double, l2: Double) -> Double {
        let brighter = max(l1, l2)
        let darker = min(l1, l2)
        return (brighter + 0.05) / (darker + 0.05)
    }

    // MARK: - Luminance & Threshold Unit Tests

    func testMathematicalLuminanceCalculation() {
        // Pure black luminance must be 0.0
        let blackL = relativeLuminance(rgb: AppRGBColor(r: 0.0, g: 0.0, b: 0.0))
        XCTAssertEqual(blackL, 0.0, accuracy: 0.0001)

        // Pure white luminance must be 1.0
        let whiteL = relativeLuminance(rgb: AppRGBColor(r: 1.0, g: 1.0, b: 1.0))
        XCTAssertEqual(whiteL, 1.0, accuracy: 0.0001)

        // White on Black contrast ratio must be 21.0
        let maxContrast = contrastRatio(l1: whiteL, l2: blackL)
        XCTAssertEqual(maxContrast, 21.0, accuracy: 0.01)

        // Piecewise sRGB boundary test: exactly at and around 0.04045 threshold
        let atThreshold = relativeLuminance(rgb: AppRGBColor(r: 0.04045, g: 0.04045, b: 0.04045))
        let expectedLin = 0.04045 / 12.92
        XCTAssertEqual(atThreshold, expectedLin, accuracy: 0.0001)
    }

    // MARK: - Text and Feedback Contrast Tests (All 5 Tokens on Theme Surfaces)

    func testTextTokensMeetWCAGAAOnCardSurfaces() {
        let lightSurfaceL = relativeLuminance(rgb: theme.colors.surfaceCard.lightRGB)
        let darkSurfaceL = relativeLuminance(rgb: theme.colors.surfaceCard.darkRGB)

        // 1. Text Primary (Light & Dark)
        let primaryLightL = relativeLuminance(rgb: theme.colors.textPrimary.lightRGB)
        let primaryDarkL = relativeLuminance(rgb: theme.colors.textPrimary.darkRGB)
        let crPrimaryLight = contrastRatio(l1: lightSurfaceL, l2: primaryLightL)
        let crPrimaryDark = contrastRatio(l1: primaryDarkL, l2: darkSurfaceL)

        XCTAssertGreaterThanOrEqual(crPrimaryLight, 7.0, "Primary text Light Mode must meet AAA (>= 7.0:1)")
        XCTAssertGreaterThanOrEqual(crPrimaryDark, 7.0, "Primary text Dark Mode must meet AAA (>= 7.0:1)")

        // 2. Text Secondary (Light & Dark)
        let secLightL = relativeLuminance(rgb: theme.colors.textSecondary.lightRGB)
        let secDarkL = relativeLuminance(rgb: theme.colors.textSecondary.darkRGB)
        let crSecLight = contrastRatio(l1: lightSurfaceL, l2: secLightL)
        let crSecDark = contrastRatio(l1: secDarkL, l2: darkSurfaceL)

        XCTAssertGreaterThanOrEqual(crSecLight, 4.5, "Secondary text Light Mode must meet AA (>= 4.5:1)")
        XCTAssertGreaterThanOrEqual(crSecDark, 4.5, "Secondary text Dark Mode must meet AA (>= 4.5:1)")
    }

    func testFeedbackTokensMeetWCAGAAOnCardSurfaces() {
        let lightSurfaceL = relativeLuminance(rgb: theme.colors.surfaceCard.lightRGB)
        let darkSurfaceL = relativeLuminance(rgb: theme.colors.surfaceCard.darkRGB)

        // 3. Success Feedback
        let succLightL = relativeLuminance(rgb: theme.colors.successFeedback.lightRGB)
        let succDarkL = relativeLuminance(rgb: theme.colors.successFeedback.darkRGB)
        XCTAssertGreaterThanOrEqual(contrastRatio(l1: lightSurfaceL, l2: succLightL), 4.5, "Success light must meet AA")
        XCTAssertGreaterThanOrEqual(contrastRatio(l1: succDarkL, l2: darkSurfaceL), 4.5, "Success dark must meet AA")

        // 4. Warning Feedback
        let warnLightL = relativeLuminance(rgb: theme.colors.warningFeedback.lightRGB)
        let warnDarkL = relativeLuminance(rgb: theme.colors.warningFeedback.darkRGB)
        XCTAssertGreaterThanOrEqual(contrastRatio(l1: lightSurfaceL, l2: warnLightL), 4.5, "Warning light must meet AA")
        XCTAssertGreaterThanOrEqual(contrastRatio(l1: warnDarkL, l2: darkSurfaceL), 4.5, "Warning dark must meet AA")

        // 5. Error Feedback
        let errLightL = relativeLuminance(rgb: theme.colors.errorFeedback.lightRGB)
        let errDarkL = relativeLuminance(rgb: theme.colors.errorFeedback.darkRGB)
        XCTAssertGreaterThanOrEqual(contrastRatio(l1: lightSurfaceL, l2: errLightL), 4.5, "Error light must meet AA")
        XCTAssertGreaterThanOrEqual(contrastRatio(l1: errDarkL, l2: darkSurfaceL), 4.5, "Error dark must meet AA")
    }

    func testDimensionAccentColorsMeetWCAGAAForNormalText() {
        let lightSurfaceL = relativeLuminance(rgb: theme.colors.surfaceCard.lightRGB)
        let darkSurfaceL = relativeLuminance(rgb: theme.colors.surfaceCard.darkRGB)

        let dimensions = ["architecture", "platform", "quality", "agile"]

        for dimId in dimensions {
            let token = theme.colorToken(forDimension: dimId)

            // Light mode token against light surface
            let lightL = relativeLuminance(rgb: token.lightRGB)
            let lightRatio = contrastRatio(l1: lightSurfaceL, l2: lightL)
            XCTAssertGreaterThanOrEqual(
                lightRatio,
                4.5,
                "Dimension '\(dimId)' Light Mode accent must achieve at least 4.5:1 against surfaceCard"
            )

            // Dark mode token against dark surface
            let darkL = relativeLuminance(rgb: token.darkRGB)
            let darkRatio = contrastRatio(l1: darkL, l2: darkSurfaceL)
            XCTAssertGreaterThanOrEqual(
                darkRatio,
                4.5,
                "Dimension '\(dimId)' Dark Mode accent must achieve at least 4.5:1 against surfaceCard"
            )
        }
    }

    func testOnAccentTextContrastMeetsWCAGAAAOnDimensionAndFeedbackButtons() {
        let onAccent = theme.colors.onAccent
        let lightTextL = relativeLuminance(rgb: onAccent.lightRGB)
        let darkTextL = relativeLuminance(rgb: onAccent.darkRGB)

        // 1. Dimension action buttons (Light Mode: white on dark accent; Dark Mode: dark text on bright accent)
        let dimensions = ["architecture", "platform", "quality", "agile"]
        for dimId in dimensions {
            let dimToken = theme.colorToken(forDimension: dimId)

            // Light Mode: white text (1.0) on dark dimension accent (e.g. 0x1E3A8A)
            let dimLightL = relativeLuminance(rgb: dimToken.lightRGB)
            let lightRatio = contrastRatio(l1: lightTextL, l2: dimLightL)
            XCTAssertGreaterThanOrEqual(
                lightRatio,
                7.0,
                "OnAccent text in Light Mode on '\(dimId)' must meet AAA (>= 7.0:1, actual: \(lightRatio))"
            )

            // Dark Mode: dark text (0x090D16) on bright pastel dimension accent (e.g. 0x38BDF8, 0xFBBF24)
            let dimDarkL = relativeLuminance(rgb: dimToken.darkRGB)
            let darkRatio = contrastRatio(l1: dimDarkL, l2: darkTextL)
            XCTAssertGreaterThanOrEqual(
                darkRatio,
                7.0,
                "OnAccent text in Dark Mode on '\(dimId)' must meet AAA (>= 7.0:1, actual: \(darkRatio))"
            )
        }

        // 2. Success feedback action button (Abschließen)
        let succToken = theme.colors.successFeedback
        let succLightRatio = contrastRatio(l1: lightTextL, l2: relativeLuminance(rgb: succToken.lightRGB))
        let succDarkRatio = contrastRatio(l1: relativeLuminance(rgb: succToken.darkRGB), l2: darkTextL)
        XCTAssertGreaterThanOrEqual(succLightRatio, 7.0, "Success button in Light Mode must meet AAA")
        XCTAssertGreaterThanOrEqual(succDarkRatio, 7.0, "Success button in Dark Mode must meet AAA")
    }

    func testSpacingAndCornerRadiusDesignTokens() {
        XCTAssertEqual(theme.spacing.xs, 4.0)
        XCTAssertEqual(theme.spacing.sm, 8.0)
        XCTAssertEqual(theme.spacing.md, 16.0)
        XCTAssertEqual(theme.spacing.lg, 24.0)
        XCTAssertEqual(theme.spacing.xl, 32.0)

        XCTAssertEqual(theme.cornerRadius.small, 8.0)
        XCTAssertEqual(theme.cornerRadius.medium, 14.0)
        XCTAssertEqual(theme.cornerRadius.large, 20.0)

        XCTAssertEqual(theme.layout.maxContentWidthiPad, 640.0)
        XCTAssertEqual(theme.layout.minTouchTargetSize, 44.0)
        XCTAssertEqual(theme.layout.primaryButtonHeight, 56.0)
    }

    func testCustomInjectedThemePolymorphism() {
        let customTheme = AppTheme(
            spacing: SpacingTokens(xs: 2.0, sm: 4.0, md: 8.0, lg: 12.0, xl: 16.0),
            layout: LayoutTokens(maxContentWidthiPad: 700.0, minTouchTargetSize: 48.0, primaryButtonHeight: 60.0)
        )

        XCTAssertEqual(customTheme.spacing.md, 8.0)
        XCTAssertEqual(customTheme.layout.maxContentWidthiPad, 700.0)
        XCTAssertEqual(customTheme.layout.minTouchTargetSize, 48.0)
    }

    func testAdaptiveColorTokenSwiftUIResolution() {
        let token = theme.colors.textPrimary
        // Exercise swiftUIColor getter
        _ = token.lightRGB.swiftUIColor
        _ = token.darkRGB.swiftUIColor

        // Exercise dynamic SwiftUI color property
        _ = token.color

        // Exercise explicit appearance mode resolution
        let lightRGB = token.resolvedRGB(isDarkMode: false)
        let darkRGB = token.resolvedRGB(isDarkMode: true)
        XCTAssertEqual(lightRGB, token.lightRGB)
        XCTAssertEqual(darkRGB, token.darkRGB)

        #if canImport(AppKit)
        if let aqua = NSAppearance(named: .aqua), let darkAqua = NSAppearance(named: .darkAqua) {
            let lightNS = token.resolvedNSColor(for: aqua)
            let darkNS = token.resolvedNSColor(for: darkAqua)
            XCTAssertNotNil(lightNS)
            XCTAssertNotNil(darkNS)
        }
        #endif

        // Exercise fallback dimension lookup
        let fallbackToken = theme.colorToken(forDimension: "unknown-dimension-id")
        XCTAssertEqual(fallbackToken, theme.colors.textSecondary)

        // Exercise hashing and equality
        XCTAssertEqual(token, theme.colors.textPrimary)
        XCTAssertNotEqual(token, theme.colors.textSecondary)
        XCTAssertEqual(token.hashValue, theme.colors.textPrimary.hashValue)
    }

    func testPlaceholderTextContrastMeetsWCAGAA() {
        let textSecondary = theme.colors.textSecondary
        let lightSurfaceL = relativeLuminance(rgb: theme.colors.surfaceCard.lightRGB)
        let darkSurfaceL = relativeLuminance(rgb: theme.colors.surfaceCard.darkRGB)

        let lightL = relativeLuminance(rgb: textSecondary.lightRGB)
        let darkL = relativeLuminance(rgb: textSecondary.darkRGB)

        let lightRatio = contrastRatio(l1: lightL, l2: lightSurfaceL)
        let darkRatio = contrastRatio(l1: darkL, l2: darkSurfaceL)

        XCTAssertGreaterThanOrEqual(lightRatio, 4.5, "Placeholder text in Light Mode must achieve >= 4.5:1 (actual: \(lightRatio))")
        XCTAssertGreaterThanOrEqual(darkRatio, 4.5, "Placeholder text in Dark Mode must achieve >= 4.5:1 (actual: \(darkRatio))")
    }
}
