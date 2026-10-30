import Foundation

/// Defines operations for loading and validating assessment catalogs.
public protocol CatalogLoaderProtocol: Sendable {
    func loadBundledCatalog() throws -> AssessmentCatalog
    func loadCatalog(from fileURL: URL) throws -> AssessmentCatalog
    func decodeCatalog(from data: Data) throws -> AssessmentCatalog
}

/// Robust JSON loader for assessment catalogs bundled with the app or loaded from sandbox storage.
public final class LocalCatalogService: CatalogLoaderProtocol {
    private let bundle: Bundle

    /// Default initializer using the SPM module resource bundle or Bundle.main for native app bundles.
    public init() {
        #if SWIFT_PACKAGE
        self.bundle = .module
        #else
        self.bundle = .main
        #endif
    }

    /// Custom initializer allowing dependency injection of a specific bundle (e.g. for testing).
    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    public func loadBundledCatalog() throws -> AssessmentCatalog {
        guard let url = bundle.url(forResource: "assessment_catalog", withExtension: "json") else {
            throw CatalogLoaderError.resourceNotFound(name: "assessment_catalog.json")
        }
        return try loadCatalog(from: url)
    }

    public func loadCatalog(from fileURL: URL) throws -> AssessmentCatalog {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw CatalogLoaderError.fileReadError(url: fileURL, underlying: error)
        }
        return try decodeCatalog(from: data)
    }

    public func decodeCatalog(from data: Data) throws -> AssessmentCatalog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let catalog: AssessmentCatalog
        do {
            catalog = try decoder.decode(AssessmentCatalog.self, from: data)
        } catch {
            throw CatalogLoaderError.jsonDecodingFailed(underlying: error)
        }

        do {
            try catalog.validateIntegrity()
        } catch {
            throw CatalogLoaderError.validationFailed(underlying: error)
        }

        return catalog
    }
}

public enum CatalogLoaderError: LocalizedError, Equatable {
    case resourceNotFound(name: String)
    case fileReadError(url: URL, underlying: String)
    case jsonDecodingFailed(underlying: String)
    case validationFailed(underlying: String)

    public static func fileReadError(url: URL, underlying: Error) -> CatalogLoaderError {
        .fileReadError(url: url, underlying: underlying.localizedDescription)
    }

    public static func jsonDecodingFailed(underlying: Error) -> CatalogLoaderError {
        .jsonDecodingFailed(underlying: underlying.localizedDescription)
    }

    public static func validationFailed(underlying: Error) -> CatalogLoaderError {
        .validationFailed(underlying: underlying.localizedDescription)
    }

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name):
            return "Catalog resource '\(name)' could not be located in bundle."
        case .fileReadError(let url, let underlying):
            return "Failed to read catalog file at '\(url.path)': \(underlying)"
        case .jsonDecodingFailed(let underlying):
            return "Failed to parse catalog JSON payload: \(underlying)"
        case .validationFailed(let underlying):
            return "Catalog integrity validation failed: \(underlying)"
        }
    }
}
