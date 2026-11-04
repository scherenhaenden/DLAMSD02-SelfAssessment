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
}
