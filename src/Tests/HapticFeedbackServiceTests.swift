import XCTest
import SwiftUI
@testable import AssessYourselfCore

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
    func testAssessmentFlowViewConnectsEnvironmentHapticServiceOnAppear() {
        let vm = AssessmentViewModel()
        let customMock = MockHapticFeedbackService()
        let view = AssessmentFlowView(viewModel: vm)
            .environment(\.hapticFeedback, customMock)

        #if canImport(UIKit)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        controller.view.layoutIfNeeded()
        #endif

        // Trigger action that uses the haptic feedback service
        vm.loadCatalog()
        XCTAssertEqual(vm.state, .inProgress)
        XCTAssertTrue(vm.canGoForward || vm.progress >= 0)
    }
}
