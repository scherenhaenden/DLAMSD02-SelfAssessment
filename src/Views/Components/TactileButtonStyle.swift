import SwiftUI

/// Tactile button style providing responsive physical press scaling and dimming
/// in accordance with Apple Human Interface Guidelines for touch feedback.
/// Automatically adapts to accessibilityReduceMotion by suppressing decorative scale transforms.
public struct TactileButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    public let pressedScale: CGFloat
    public let pressedOpacity: Double
    private let overrideReduceMotion: Bool?

    public init(
        pressedScale: CGFloat = 0.98,
        pressedOpacity: Double = 0.92,
        overrideReduceMotion: Bool? = nil
    ) {
        self.pressedScale = pressedScale
        self.pressedOpacity = pressedOpacity
        self.overrideReduceMotion = overrideReduceMotion
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let reduceMotion = overrideReduceMotion ?? systemReduceMotion
        let effectiveScale = reduceMotion ? 1.0 : (isPressed ? pressedScale : 1.0)
        let effectiveOpacity = isPressed ? pressedOpacity : 1.0

        configuration.label
            .scaleEffect(effectiveScale)
            .opacity(effectiveOpacity)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isPressed)
    }
}

public extension View {
    /// Applies a standard tactile press feedback animation to interactive touch targets.
    func tactileFeedback(scale: CGFloat = 0.98) -> some View {
        self.buttonStyle(TactileButtonStyle(pressedScale: scale))
    }
}
