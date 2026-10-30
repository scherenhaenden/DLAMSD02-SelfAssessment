import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A normalized RGB color representation in sRGB color space [0.0 ... 1.0].
public struct AppRGBColor: Sendable, Hashable {
    public let r: Double
    public let g: Double
    public let b: Double

    public init(r: Double, g: Double, b: Double) {
        self.r = min(1.0, max(0.0, r))
        self.g = min(1.0, max(0.0, g))
        self.b = min(1.0, max(0.0, b))
    }

    public init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(r: r, g: g, b: b)
    }

    /// Converts normalized sRGB components to SwiftUI Color.
    public var swiftUIColor: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

/// A semantic adaptive color pair with guaranteed WCAG contrast.
public struct AdaptiveColorToken: Sendable, Hashable {
    public let lightRGB: AppRGBColor
    public let darkRGB: AppRGBColor

    public init(lightRGB: AppRGBColor, darkRGB: AppRGBColor) {
        self.lightRGB = lightRGB
        self.darkRGB = darkRGB
    }

    /// Returns the resolved normalized RGB for the requested appearance mode.
    public func resolvedRGB(isDarkMode: Bool) -> AppRGBColor {
        isDarkMode ? darkRGB : lightRGB
    }

    #if canImport(AppKit)
    /// Resolves the adaptive color for an explicit AppKit appearance (used for macOS rendering and headless testing).
    public func resolvedNSColor(for appearance: NSAppearance) -> NSColor {
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let rgb = resolvedRGB(isDarkMode: isDark)
        return NSColor(srgbRed: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1.0)
    }
    #endif

    #if canImport(UIKit)
    /// Resolves the adaptive color for an explicit UIKit trait collection (used for iOS rendering and testing).
    public func resolvedUIColor(for traitCollection: UITraitCollection) -> UIColor {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let rgb = resolvedRGB(isDarkMode: isDark)
        return UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1.0)
    }
    #endif

    /// Dynamic SwiftUI Color adapting automatically to Light/Dark Mode.
    public var color: Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            self.resolvedUIColor(for: traitCollection)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            self.resolvedNSColor(for: appearance)
        })
        #else
        return lightRGB.swiftUIColor
        #endif
    }
}
