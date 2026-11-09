import Foundation

/// Defines persistent storage and backup operations for dynamic assessment catalogs in the application sandbox.
public protocol SandboxCatalogStoreProtocol: AnyObject, Sendable {
    var activeFileURL: URL { get }
    var backupFileURL: URL { get }
    var hasCustomCatalog: Bool { get }

    func loadActiveCatalog() throws -> AssessmentCatalog
    func saveCustomCatalog(_ catalog: AssessmentCatalog) throws
    func importCatalog(from data: Data) throws -> AssessmentCatalog
    func resetToBundledCatalog() throws
    func exportCatalogData() throws -> Data
}

/// Production implementation of `SandboxCatalogStoreProtocol` managing sandbox persistence,
/// atomic JSON writes, transactional `.bak` backups, and automatic recovery rollback.
public final class SandboxCatalogStore: SandboxCatalogStoreProtocol, @unchecked Sendable {
    public static let standardSubdirectory = "AssessYourself"
    public static let catalogFileName = "custom_assessments.json"
    public static let backupFileName = "custom_assessments.json.bak"

    public let directoryURL: URL
    public let activeFileURL: URL
    public let backupFileURL: URL

    private let catalogLoader: CatalogLoaderProtocol
    private let fileManager: FileManager
    private let lock = NSLock()

    /// Default initializer using Application Support/AssessYourself directory.
    public init(
        baseURL: URL? = nil,
        catalogLoader: CatalogLoaderProtocol = LocalCatalogService(),
        fileManager: FileManager = .default
    ) {
        let directory: URL
        if let customBase = baseURL {
            directory = customBase
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            directory = appSupport.appendingPathComponent(Self.standardSubdirectory, isDirectory: true)
        }

        self.directoryURL = directory
        self.activeFileURL = directory.appendingPathComponent(Self.catalogFileName, isDirectory: false)
        self.backupFileURL = directory.appendingPathComponent(Self.backupFileName, isDirectory: false)
        self.catalogLoader = catalogLoader
        self.fileManager = fileManager
    }

    public var hasCustomCatalog: Bool {
        lock.lock()
        defer { lock.unlock() }
        return fileManager.fileExists(atPath: activeFileURL.path)
    }

    /// Loads the active catalog.
    /// If no custom catalog exists, returns the default bundled catalog.
    /// If custom catalog exists but is corrupted, triggers transactional rollback to `.bak` if valid.
    public func loadActiveCatalog() throws -> AssessmentCatalog {
        lock.lock()
        defer { lock.unlock() }

        guard fileManager.fileExists(atPath: activeFileURL.path) else {
            return try catalogLoader.loadBundledCatalog()
        }

        do {
            let data = try Data(contentsOf: activeFileURL)
            return try catalogLoader.decodeCatalog(from: data)
        } catch let primaryError {
            // Active file corrupted: check if backup exists for automatic rollback
            if fileManager.fileExists(atPath: backupFileURL.path) {
                do {
                    let backupData = try Data(contentsOf: backupFileURL)
                    _ = try catalogLoader.decodeCatalog(from: backupData)
                    // Rollback: restore backup data to active file
                    try backupData.write(to: activeFileURL, options: .atomic)
                    throw SandboxCatalogError.corruptedRollbackTriggered(underlying: primaryError.localizedDescription)
                } catch let rollbackError as SandboxCatalogError {
                    throw rollbackError
                } catch {
                    throw SandboxCatalogError.corruptedRollbackFailed(underlying: primaryError.localizedDescription)
                }
            } else {
                throw SandboxCatalogError.corruptedNoBackup(underlying: primaryError.localizedDescription)
            }
        }
    }

    /// Validates and atomically persists a custom assessment catalog, creating a `.bak` backup first.
    public func saveCustomCatalog(_ catalog: AssessmentCatalog) throws {
        lock.lock()
        defer { lock.unlock() }

        do {
            try catalog.validateIntegrity()
        } catch {
            throw SandboxCatalogError.catalogValidationFailed(underlying: error.localizedDescription)
        }

        do {
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }

            // Create or replace .bak backup before overwriting active file
            if fileManager.fileExists(atPath: activeFileURL.path) {
                if fileManager.fileExists(atPath: backupFileURL.path) {
                    try? fileManager.removeItem(at: backupFileURL)
                }
                try fileManager.copyItem(at: activeFileURL, to: backupFileURL)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(catalog)
            try data.write(to: activeFileURL, options: .atomic)
        } catch let error as SandboxCatalogError {
            throw error
        } catch {
            throw SandboxCatalogError.ioError(underlying: error.localizedDescription)
        }
    }

    /// Decodes external JSON data, validates invariants, and persists it with automatic backup.
    public func importCatalog(from data: Data) throws -> AssessmentCatalog {
        let imported: AssessmentCatalog
        do {
            imported = try catalogLoader.decodeCatalog(from: data)
        } catch {
            throw SandboxCatalogError.catalogValidationFailed(underlying: error.localizedDescription)
        }

        try saveCustomCatalog(imported)
        return imported
    }

    /// Resets sandbox storage by deleting custom catalog and backup files, returning to bundled catalog.
    public func resetToBundledCatalog() throws {
        lock.lock()
        defer { lock.unlock() }

        if fileManager.fileExists(atPath: activeFileURL.path) {
            try fileManager.removeItem(at: activeFileURL)
        }
        if fileManager.fileExists(atPath: backupFileURL.path) {
            try fileManager.removeItem(at: backupFileURL)
        }
    }

    /// Exports active catalog as formatted JSON Data.
    public func exportCatalogData() throws -> Data {
        let catalog = try loadActiveCatalog()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(catalog)
    }
}

public enum SandboxCatalogError: LocalizedError, Equatable {
    case corruptedRollbackTriggered(underlying: String)
    case corruptedRollbackFailed(underlying: String)
    case corruptedNoBackup(underlying: String)
    case ioError(underlying: String)
    case catalogValidationFailed(underlying: String)

    public var errorDescription: String? {
        switch self {
        case .corruptedRollbackTriggered(let reason):
            return "Aktiver Sandbox-Katalog war beschädigt. Automatischer Rollback auf die Sicherungskopie (.bak) wurde erfolgreich ausgeführt: \(reason)"
        case .corruptedRollbackFailed(let reason):
            return "Aktiver Katalog und Sicherungskopie (.bak) sind beide beschädigt. Rollback fehlgeschlagen: \(reason)"
        case .corruptedNoBackup(let reason):
            return "Aktiver Sandbox-Katalog ist beschädigt und keine Sicherungskopie (.bak) verfügbar: \(reason)"
        case .ioError(let reason):
            return "Dateisystem-Fehler im Sandbox-Katalog: \(reason)"
        case .catalogValidationFailed(let reason):
            return "Integritätsprüfung des Katalogs fehlgeschlagen: \(reason)"
        }
    }
}
