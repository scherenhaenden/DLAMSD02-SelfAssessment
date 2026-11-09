import Foundation

/// Thread-safe local persistence service for assessment records using `UserDefaults` and `Codable` JSON serialization.
/// Enforces a strict FIFO retention policy of up to 50 records sorted by `completedAt` descending (newest first).
public final class UserDefaultsHistoryStore: HistoryStoreProtocol, @unchecked Sendable {
    public static let defaultStorageKey = "de.iu.assessyourself.history.records.v1"
    public static let uiTestStorageKey = "de.iu.assessyourself.history.records.uitest"
    public static let defaultMaxCapacity = 50

    private let userDefaults: UserDefaults
    private let storageKey: String
    private let maxCapacity: Int
    private let lock = NSLock()
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    public init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = UserDefaultsHistoryStore.defaultStorageKey,
        maxCapacity: Int = UserDefaultsHistoryStore.defaultMaxCapacity
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.maxCapacity = max(1, maxCapacity)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder
    }

    // MARK: - HistoryStoreProtocol

    public func loadHistory() throws -> [AssessmentRecord] {
        lock.lock()
        defer { lock.unlock() }

        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let records = try jsonDecoder.decode([AssessmentRecord].self, from: data)
            // Explicitly sort by completedAt descending (newest first).
            // Do NOT rely on AssessmentRecord.< which sorts by overallScore.
            return records.sorted { lhs, rhs in
                if lhs.completedAt != rhs.completedAt {
                    return lhs.completedAt > rhs.completedAt
                }
                return lhs.id.uuidString > rhs.id.uuidString
            }
        } catch {
            // Defensive: do NOT wipe corrupted data; surface descriptive error.
            throw HistoryStoreError.corruptedData("Failed to decode history: \(error.localizedDescription)")
        }
    }

    public func save(record: AssessmentRecord) throws {
        lock.lock()
        defer { lock.unlock() }

        var currentRecords: [AssessmentRecord] = []
        if let data = userDefaults.data(forKey: storageKey) {
            do {
                currentRecords = try jsonDecoder.decode([AssessmentRecord].self, from: data)
            } catch {
                throw HistoryStoreError.corruptedData("Cannot save into corrupted store: \(error.localizedDescription)")
            }
        }

        // Idempotency: replace if record with identical ID already exists, otherwise append
        if let existingIndex = currentRecords.firstIndex(where: { $0.id == record.id }) {
            currentRecords[existingIndex] = record
        } else {
            currentRecords.append(record)
        }

        // Strict chronological sorting descending (newest first)
        currentRecords.sort { lhs, rhs in
            if lhs.completedAt != rhs.completedAt {
                return lhs.completedAt > rhs.completedAt
            }
            return lhs.id.uuidString > rhs.id.uuidString
        }

        // Pure FIFO capacity pruning: retain at most maxCapacity (drop oldest)
        if currentRecords.count > maxCapacity {
            currentRecords = Array(currentRecords.prefix(maxCapacity))
        }

        do {
            let encodedData = try jsonEncoder.encode(currentRecords)
            userDefaults.set(encodedData, forKey: storageKey)
        } catch {
            throw HistoryStoreError.storageFailure("Failed to encode history records: \(error.localizedDescription)")
        }
    }

    public func clearHistory() throws {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.removeObject(forKey: storageKey)
    }
}
