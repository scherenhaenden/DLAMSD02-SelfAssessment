import Foundation

/// Errors that can occur during history persistence operations.
public enum HistoryStoreError: Error, LocalizedError, Equatable {
    case corruptedData(String)
    case storageFailure(String)

    public var errorDescription: String? {
        switch self {
        case .corruptedData(let message):
            return "History store data corrupted: \(message)"
        case .storageFailure(let message):
            return "History store operation failed: \(message)"
        }
    }
}

/// Abstract contract for locally storing and retrieving completed assessment histories.
public protocol HistoryStoreProtocol: AnyObject, Sendable {
    /// Loads all saved assessment records, strictly ordered by `completedAt` descending (newest first).
    func loadHistory() throws -> [AssessmentRecord]

    /// Idempotently saves an assessment record.
    /// If a record with the same `id` already exists, it is updated.
    /// Storage capacity is capped at 50 records via FIFO (oldest by `completedAt` evicted).
    func save(record: AssessmentRecord) throws

    /// Removes all stored records from the persistent store.
    func clearHistory() throws
}
