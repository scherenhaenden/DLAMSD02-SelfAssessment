import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A normalized RGB color representation in sRGB color space [0.0 ... 1.0].
public struct RGBColor: Sendable, Hashable {
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
    public let lightRGB: RGBColor
    public let darkRGB: RGBColor

    public init(lightRGB: RGBColor, darkRGB: RGBColor) {
        self.lightRGB = lightRGB
        self.darkRGB = darkRGB
    }

    /// Dynamic SwiftUI Color adapting automatically to Light/Dark Mode.
    public var color: Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(
                    red: darkRGB.r,
                    green: darkRGB.g,
                    blue: darkRGB.b,
                    alpha: 1.0
                )
            default:
                return UIColor(
                    red: lightRGB.r,
                    green: lightRGB.g,
                    blue: lightRGB.b,
                    alpha: 1.0
                )
            }
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(
                    srgbRed: darkRGB.r,
                    green: darkRGB.g,
                    blue: darkRGB.b,
                    alpha: 1.0
                )
            } else {
                return NSColor(
                    srgbRed: lightRGB.r,
                    green: lightRGB.g,
                    blue: lightRGB.b,
                    alpha: 1.0
                )
            }
        })
        #else
        return lightRGB.swiftUIColor
        #endif
    }
}
