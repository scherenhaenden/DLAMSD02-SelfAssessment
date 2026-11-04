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

    public func effectiveScale(isPressed: Bool, reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 1.0 : (isPressed ? pressedScale : 1.0)
    }

    public func effectiveOpacity(isPressed: Bool) -> Double {
        isPressed ? pressedOpacity : 1.0
    }

    public func effectiveAnimation(isPressed: Bool, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.12)
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let reduceMotion = overrideReduceMotion ?? systemReduceMotion
        let scale = effectiveScale(isPressed: isPressed, reduceMotion: reduceMotion)
        let opacity = effectiveOpacity(isPressed: isPressed)
        let anim = effectiveAnimation(isPressed: isPressed, reduceMotion: reduceMotion)

        configuration.label
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(anim, value: isPressed)
    }
}

public extension View {
    /// Applies a standard tactile press feedback animation to interactive touch targets.
    func tactileFeedback(scale: CGFloat = 0.98) -> some View {
        self.buttonStyle(TactileButtonStyle(pressedScale: scale))
    }
}
