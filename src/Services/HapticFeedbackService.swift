import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Haptic Types

/// Intensity spectrum for tactile impact feedbacks matching UIKit/CoreHaptics capabilities.
public enum HapticImpactIntensity: String, CaseIterable, Sendable {
    case light
    case medium
    case heavy
    case rigid
    case soft
}

/// Notification outcome types for sensory state reinforcement.
public enum HapticNotificationType: String, CaseIterable, Sendable {
    case success
    case warning
    case error
}

// MARK: - Protocol Contract

/// Domain abstraction for tactile feedback decoupling the presentation and view-model layers
/// from UIKit hardware dependencies, enabling crash-free testability and cross-platform safety.
public protocol HapticFeedbackServiceProtocol: AnyObject, Sendable {
    /// Pre-warms the sensory actuators to eliminate feedback latency on upcoming interactions.
    func prepare()

    /// Triggers a discrete selection tick (e.g. choice option selection or slider tick).
    func triggerSelection()

    /// Triggers an impact with the specified tactile intensity (e.g. navigation advance or modal dismiss).
    func triggerImpact(_ intensity: HapticImpactIntensity)

    /// Triggers a multimodal notification feedback (e.g. assessment submission or error).
    func triggerNotification(_ type: HapticNotificationType)
}

// MARK: - Production Implementation

/// Production haptic feedback service managing retained generator instances and thread-safe dispatch.
/// Safely falls back on platforms lacking tactile hardware (macOS, iPadOS, Catalyst, Simulator).
public final class SystemHapticFeedbackService: HapticFeedbackServiceProtocol, @unchecked Sendable {
    private let stateLock = NSLock()
    private var _isEnabled: Bool

    public var isEnabled: Bool {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _isEnabled
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            _isEnabled = newValue
        }
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var impactGenerators: [HapticImpactIntensity: UIImpactFeedbackGenerator] = [:]
    private var notificationGenerator: UINotificationFeedbackGenerator?
    private let generatorLock = NSLock()
    #endif

    public init(isEnabled: Bool = true) {
        self._isEnabled = isEnabled
    }

    public func prepare() {
        guard isEnabled else { return }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.generatorLock.lock()
            if self.selectionGenerator == nil {
                self.selectionGenerator = UISelectionFeedbackGenerator()
            }
            if self.notificationGenerator == nil {
                self.notificationGenerator = UINotificationFeedbackGenerator()
            }
            if self.impactGenerators[.light] == nil {
                self.impactGenerators[.light] = UIImpactFeedbackGenerator(style: .light)
            }
            if self.impactGenerators[.medium] == nil {
                self.impactGenerators[.medium] = UIImpactFeedbackGenerator(style: .medium)
            }
            let selGen = self.selectionGenerator
            let notifGen = self.notificationGenerator
            let lightGen = self.impactGenerators[.light]
            let medGen = self.impactGenerators[.medium]
            self.generatorLock.unlock()

            selGen?.prepare()
            notifGen?.prepare()
            lightGen?.prepare()
            medGen?.prepare()
        }
        #endif
    }

    public func triggerSelection() {
        guard isEnabled else { return }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.generatorLock.lock()
            if self.selectionGenerator == nil {
                self.selectionGenerator = UISelectionFeedbackGenerator()
            }
            let generator = self.selectionGenerator
            self.generatorLock.unlock()

            generator?.selectionChanged()
            generator?.prepare()
        }
        #endif
    }

    public func triggerImpact(_ intensity: HapticImpactIntensity) {
        guard isEnabled else { return }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.generatorLock.lock()
            let generator: UIImpactFeedbackGenerator
            if let existing = self.impactGenerators[intensity] {
                generator = existing
            } else {
                let style: UIImpactFeedbackGenerator.FeedbackStyle
                switch intensity {
                case .light: style = .light
                case .medium: style = .medium
                case .heavy: style = .heavy
                case .rigid: style = .rigid
                case .soft: style = .soft
                }
                generator = UIImpactFeedbackGenerator(style: style)
                self.impactGenerators[intensity] = generator
            }
            self.generatorLock.unlock()

            generator.impactOccurred()
            generator.prepare()
        }
        #endif
    }

    public func triggerNotification(_ type: HapticNotificationType) {
        guard isEnabled else { return }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.generatorLock.lock()
            if self.notificationGenerator == nil {
                self.notificationGenerator = UINotificationFeedbackGenerator()
            }
            let generator = self.notificationGenerator
            self.generatorLock.unlock()

            let feedbackType: UINotificationFeedbackGenerator.FeedbackType
            switch type {
            case .success: feedbackType = .success
            case .warning: feedbackType = .warning
            case .error: feedbackType = .error
            }
            generator?.notificationOccurred(feedbackType)
            generator?.prepare()
        }
        #endif
    }
}

// MARK: - Test Spy Implementation

/// Fully deterministic mock implementation for unit and integration testing without hardware dependencies.
public final class MockHapticFeedbackService: HapticFeedbackServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _prepareCount: Int = 0
    private var _selectionCount: Int = 0
    private var _recordedImpacts: [HapticImpactIntensity] = []
    private var _recordedNotifications: [HapticNotificationType] = []

    public init() {}

    public var prepareCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _prepareCount
    }

    public var selectionCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _selectionCount
    }

    public var recordedImpacts: [HapticImpactIntensity] {
        lock.lock()
        defer { lock.unlock() }
        return _recordedImpacts
    }

    public var recordedNotifications: [HapticNotificationType] {
        lock.lock()
        defer { lock.unlock() }
        return _recordedNotifications
    }

    public func prepare() {
        lock.lock()
        _prepareCount += 1
        lock.unlock()
    }

    public func triggerSelection() {
        lock.lock()
        _selectionCount += 1
        lock.unlock()
    }

    public func triggerImpact(_ intensity: HapticImpactIntensity) {
        lock.lock()
        _recordedImpacts.append(intensity)
        lock.unlock()
    }

    public func triggerNotification(_ type: HapticNotificationType) {
        lock.lock()
        _recordedNotifications.append(type)
        lock.unlock()
    }

    public func reset() {
        lock.lock()
        _prepareCount = 0
        _selectionCount = 0
        _recordedImpacts.removeAll()
        _recordedNotifications.removeAll()
        lock.unlock()
    }
}

// MARK: - SwiftUI Environment Key

private struct HapticFeedbackKey: EnvironmentKey {
    static let defaultValue: any HapticFeedbackServiceProtocol = SystemHapticFeedbackService()
}

public extension EnvironmentValues {
    var hapticFeedback: any HapticFeedbackServiceProtocol {
        get { self[HapticFeedbackKey.self] }
        set { self[HapticFeedbackKey.self] = newValue }
    }
}
