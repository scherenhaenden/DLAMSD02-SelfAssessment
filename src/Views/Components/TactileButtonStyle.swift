import SwiftUI

/// Tactile button style providing responsive physical press scaling and dimming
/// in accordance with Apple Human Interface Guidelines for touch feedback.
public struct TactileButtonStyle: ButtonStyle {
    private let pressedScale: CGFloat
    private let pressedOpacity: Double

    public init(pressedScale: CGFloat = 0.98, pressedOpacity: Double = 0.92) {
        self.pressedScale = pressedScale
        self.pressedOpacity = pressedOpacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension View {
    /// Applies a standard tactile press feedback animation to interactive touch targets.
    func tactileFeedback(scale: CGFloat = 0.98) -> some View {
        self.buttonStyle(TactileButtonStyle(pressedScale: scale))
    }
}
