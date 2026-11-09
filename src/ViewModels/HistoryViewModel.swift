import Foundation
import Combine

/// Identifiable enum for modal alerts displayed within the assessment history screen.
public enum HistoryAlertItem: Identifiable, Equatable {
    case clearAll
    case resetCorrupted

    public var id: Int {
        switch self {
        case .clearAll: return 1
        case .resetCorrupted: return 2
        }
    }
}

/// Protocol defining the state contract and user actions for the assessment history log.
public protocol HistoryViewModelProtocol: ObservableObject {
    var records: [AssessmentRecord] { get }
    var errorMessage: String? { get }
    var activeAlert: HistoryAlertItem? { get set }

    func loadRecords()
    func clearAllHistory()
    func requestResetCorrupted()
    func requestClearAll()
    func confirmActiveAlert()
    func dismissAlert()
}

/// ViewModel coordinating persistent history loading, defensive error handling,
/// temporal progress comparisons, and user-initiated history reset / corruption recovery.
public final class HistoryViewModel: HistoryViewModelProtocol {
    public let historyStore: any HistoryStoreProtocol

    @Published public private(set) var records: [AssessmentRecord] = []
    @Published public private(set) var errorMessage: String?
    @Published public var activeAlert: HistoryAlertItem?

    public init(historyStore: any HistoryStoreProtocol = UserDefaultsHistoryStore()) {
        self.historyStore = historyStore
    }

    public func loadRecords() {
        do {
            records = try historyStore.loadHistory()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func clearAllHistory() {
        do {
            try historyStore.clearHistory()
            records.removeAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func requestResetCorrupted() {
        activeAlert = .resetCorrupted
    }

    public func requestClearAll() {
        activeAlert = .clearAll
    }

    public func confirmActiveAlert() {
        switch activeAlert {
        case .clearAll, .resetCorrupted:
            clearAllHistory()
        case .none:
            break
        }
        activeAlert = nil
    }

    public func dismissAlert() {
        activeAlert = nil
    }
}
