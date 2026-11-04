import XCTest
import SwiftUI
@testable import AssessYourselfCore

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

@MainActor
private func hostLifecycle<V: View>(_ view: V) -> () -> Void {
    _ = NSApplication.shared
    let controller = NSHostingController(rootView: view)
    let window = NSWindow(contentViewController: controller)
    window.isReleasedWhenClosed = false
    window.alphaValue = 0
    window.setContentSize(NSSize(width: 375, height: 667))
    window.makeKeyAndOrderFront(nil)
    controller.view.layoutSubtreeIfNeeded()
    RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    return {
        window.close()
    }
}
#elseif canImport(UIKit)
import UIKit

@MainActor
private func hostLifecycle<V: View>(_ view: V) -> () -> Void {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
    let controller = UIHostingController(rootView: view)
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.layoutIfNeeded()
    RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    return {
        window.isHidden = true
    }
}
#else
private func hostLifecycle<V: View>(_ view: V) -> () -> Void {
    return {}
}
#endif

final class HapticFeedbackServiceTests: XCTestCase {

    func testMockHapticFeedbackServiceRecordsAllEventsAccurately() {
        let mock = MockHapticFeedbackService()
        XCTAssertEqual(mock.prepareCount, 0)
        XCTAssertEqual(mock.selectionCount, 0)
        XCTAssertTrue(mock.recordedImpacts.isEmpty)
        XCTAssertTrue(mock.recordedNotifications.isEmpty)

        // 1. Prepare
        mock.prepare()
        XCTAssertEqual(mock.prepareCount, 1)

        // 2. Selection
        mock.triggerSelection()
        mock.triggerSelection()
        XCTAssertEqual(mock.selectionCount, 2)

        // 3. Impact spectrum
        for intensity in HapticImpactIntensity.allCases {
            mock.triggerImpact(intensity)
        }
        XCTAssertEqual(mock.recordedImpacts, [.light, .medium, .heavy, .rigid, .soft])

        // 4. Notifications
        for notification in HapticNotificationType.allCases {
            mock.triggerNotification(notification)
        }
        XCTAssertEqual(mock.recordedNotifications, [.success, .warning, .error])

        // 5. Reset
        mock.reset()
        XCTAssertEqual(mock.prepareCount, 0)
        XCTAssertEqual(mock.selectionCount, 0)
        XCTAssertTrue(mock.recordedImpacts.isEmpty)
        XCTAssertTrue(mock.recordedNotifications.isEmpty)
    }

    func testMockHapticFeedbackServiceThreadSafety() {
        let mock = MockHapticFeedbackService()
        let iterations = 100
        DispatchQueue.concurrentPerform(iterations: iterations) { idx in
            mock.prepare()
            mock.triggerSelection()
            mock.triggerImpact(idx % 2 == 0 ? .light : .heavy)
            mock.triggerNotification(idx % 2 == 0 ? .success : .warning)
        }

        XCTAssertEqual(mock.prepareCount, iterations)
        XCTAssertEqual(mock.selectionCount, iterations)
        XCTAssertEqual(mock.recordedImpacts.count, iterations)
        XCTAssertEqual(mock.recordedNotifications.count, iterations)
    }

    func testSystemHapticFeedbackServiceExecutesSafely() {
        let service = SystemHapticFeedbackService(isEnabled: true)
        XCTAssertTrue(service.isEnabled)

        // Must execute cleanly without exception on any target platform
        service.prepare()
        service.triggerSelection()

        for intensity in HapticImpactIntensity.allCases {
            service.triggerImpact(intensity)
        }

        for notif in HapticNotificationType.allCases {
            service.triggerNotification(notif)
        }

        // Disabled mode should early-return cleanly
        service.isEnabled = false
        service.prepare()
        service.triggerSelection()
        service.triggerImpact(.heavy)
        service.triggerNotification(.error)
        XCTAssertFalse(service.isEnabled)
    }

    func testEnvironmentValuesHapticKeyInjection() {
        var env = EnvironmentValues()
        XCTAssertNotNil(env.hapticFeedback)

        let customMock = MockHapticFeedbackService()
        env.hapticFeedback = customMock

        env.hapticFeedback.triggerSelection()
        XCTAssertEqual(customMock.selectionCount, 1)
    }

    func testSystemHapticFeedbackServiceConcurrentReadWriteThreadSafety() {
        let service = SystemHapticFeedbackService(isEnabled: true)
        let iterations = 1000

        DispatchQueue.concurrentPerform(iterations: 4) { threadIndex in
            for i in 0..<iterations {
                if threadIndex == 0 {
                    service.isEnabled = (i % 2 == 0)
                } else if threadIndex == 1 {
                    service.triggerSelection()
                } else if threadIndex == 2 {
                    service.triggerImpact(i % 2 == 0 ? .light : .medium)
                } else {
                    service.prepare()
                    service.triggerNotification(i % 2 == 0 ? .success : .error)
                }
            }
        }

        // Service remains stable and consistent after high-frequency concurrency
        XCTAssertNotNil(service)
    }

    @MainActor
    func testExplicitDisabledSystemServiceSurvivesViewAppearance() {
        let configured = SystemHapticFeedbackService(isEnabled: false)
        let vm = AssessmentViewModel(hapticService: configured)
        XCTAssertTrue(vm.hasExplicitHapticService)

        let cleanup = hostLifecycle(AssessmentFlowView(viewModel: vm))
        defer { cleanup() }

        let effective = vm.hapticService as? SystemHapticFeedbackService
        XCTAssertTrue(vm.hapticService === configured, "View appearance must preserve the explicitly configured service")
        XCTAssertEqual(effective?.isEnabled, false, "A service disabled by the caller must stay disabled")
    }

    @MainActor
    func testCustomEnvironmentServiceActuallyReceivesEvents() {
        let vm = AssessmentViewModel()
        XCTAssertFalse(vm.hasExplicitHapticService)

        let spy = MockHapticFeedbackService()
        let cleanup = hostLifecycle(AssessmentFlowView(viewModel: vm).environment(\.hapticFeedback, spy))
        defer { cleanup() }

        XCTAssertTrue(vm.hapticService === spy, "Environment haptic service must be connected when no explicit service was provided")

        // Trigger action that uses the haptic feedback service
        vm.loadCatalog()
        XCTAssertEqual(spy.prepareCount, 1, "Connected environment mock must actually receive events")
        XCTAssertEqual(vm.state, .inProgress)
    }
}
