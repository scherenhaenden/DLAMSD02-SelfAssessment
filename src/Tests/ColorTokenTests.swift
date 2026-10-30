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

    private func relativeLuminance(r: Double, g: Double, b: Double) -> Double {
        func channelLinear(_ c: Double) -> Double {
            return c <= 0.04045 ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
        }
        let rLin = channelLinear(r)
        let gLin = channelLinear(g)
        let bLin = channelLinear(b)
        return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin
    }

    private func contrastRatio(l1: Double, l2: Double) -> Double {
        let brighter = max(l1, l2)
        let darker = min(l1, l2)
        return (brighter + 0.05) / (darker + 0.05)
    }

    // MARK: - Unit Tests

    func testMathematicalLuminanceCalculation() {
        // Pure black luminance must be 0.0
        let blackL = relativeLuminance(r: 0.0, g: 0.0, b: 0.0)
        XCTAssertEqual(blackL, 0.0, accuracy: 0.0001)

        // Pure white luminance must be 1.0
        let whiteL = relativeLuminance(r: 1.0, g: 1.0, b: 1.0)
        XCTAssertEqual(whiteL, 1.0, accuracy: 0.0001)

        // White on Black contrast ratio must be 21.0
        let maxContrast = contrastRatio(l1: whiteL, l2: blackL)
        XCTAssertEqual(maxContrast, 21.0, accuracy: 0.01)
    }

    func testLightModeTextOnSurfaceMeetsWCAGAA() {
        // Light mode surface background: #FFFFFF (L = 1.0)
        let surfaceL = relativeLuminance(r: 1.0, g: 1.0, b: 1.0)

        // Primary text light: #0F172A (r: 15/255, g: 23/255, b: 42/255)
        let textRgb = theme.colors.textPrimary.lightRGB
        let textL = relativeLuminance(r: textRgb.r, g: textRgb.g, b: textRgb.b)
        let ratio = contrastRatio(l1: surfaceL, l2: textL)

        // WCAG AAA requires >= 7.0:1
        XCTAssertGreaterThanOrEqual(ratio, 7.0, "Primary text in Light Mode must meet WCAG AAA (>= 7.0:1)")
    }

    func testDarkModeTextOnSurfaceMeetsWCAGAA() {
        // Dark mode card surface: #1E293B (r: 30/255, g: 41/255, b: 59/255)
        let surfaceRgb = theme.colors.surfaceCard.darkRGB
        let surfaceL = relativeLuminance(r: surfaceRgb.r, g: surfaceRgb.g, b: surfaceRgb.b)

        // Primary text dark: #F8FAFC (r: 248/255, g: 250/255, b: 252/255)
        let textRgb = theme.colors.textPrimary.darkRGB
        let textL = relativeLuminance(r: textRgb.r, g: textRgb.g, b: textRgb.b)
        let ratio = contrastRatio(l1: textL, l2: surfaceL)

        // WCAG AAA requires >= 7.0:1
        XCTAssertGreaterThanOrEqual(ratio, 7.0, "Primary text in Dark Mode must meet WCAG AAA (>= 7.0:1)")
    }

    func testDimensionAccentColorsMeetWCAGAAForNormalText() {
        let whiteL = relativeLuminance(r: 1.0, g: 1.0, b: 1.0)
        let darkSurfaceL = relativeLuminance(r: 30.0 / 255.0, g: 41.0 / 255.0, b: 59.0 / 255.0)

        // Test each dimension's light and dark tokens via instance method
        let dimensions = ["architecture", "platform", "quality", "agile"]

        for dimId in dimensions {
            let token = theme.colorToken(forDimension: dimId)

            // Light mode token against white background
            let lightRgb = token.lightRGB
            let lightL = relativeLuminance(r: lightRgb.r, g: lightRgb.g, b: lightRgb.b)
            let lightRatio = contrastRatio(l1: whiteL, l2: lightL)
            XCTAssertGreaterThanOrEqual(
                lightRatio,
                4.5,
                "Dimension '\(dimId)' Light Mode accent must achieve at least 4.5:1 against white"
            )

            // Dark mode token against dark surface (#1E293B)
            let darkRgb = token.darkRGB
            let darkL = relativeLuminance(r: darkRgb.r, g: darkRgb.g, b: darkRgb.b)
            let darkRatio = contrastRatio(l1: darkL, l2: darkSurfaceL)
            XCTAssertGreaterThanOrEqual(
                darkRatio,
                4.5,
                "Dimension '\(dimId)' Dark Mode accent must achieve at least 4.5:1 against dark surface"
            )
        }
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
        // Demonstrate DI without static coupling: create a high-density, custom-spaced theme
        let customTheme = AppTheme(
            spacing: SpacingTokens(xs: 2.0, sm: 4.0, md: 8.0, lg: 12.0, xl: 16.0),
            layout: LayoutTokens(maxContentWidthiPad: 700.0, minTouchTargetSize: 48.0, primaryButtonHeight: 60.0)
        )

        XCTAssertEqual(customTheme.spacing.md, 8.0)
        XCTAssertEqual(customTheme.layout.maxContentWidthiPad, 700.0)
        XCTAssertEqual(customTheme.layout.minTouchTargetSize, 48.0)
    }
}
