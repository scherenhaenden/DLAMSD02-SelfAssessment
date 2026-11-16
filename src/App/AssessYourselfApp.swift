import SwiftUI

#if !SWIFT_PACKAGE
/// Root SwiftUI application entry point configuring shared persistence stores and tab navigation.
@main
struct AssessYourselfApp: App {
    private let historyStore: UserDefaultsHistoryStore
    private let catalogStore: SandboxCatalogStore
    @StateObject private var viewModel: AssessmentViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var catalogManagerViewModel: CatalogManagerViewModel
    @State private var selectedTab: Int = 0

    /// Initializes the history and catalog stores, applying isolated UI-test overrides in DEBUG builds.
    init() {
        #if DEBUG
        var activeStorageKey = UserDefaultsHistoryStore.defaultStorageKey
        if CommandLine.arguments.contains("--uitesting") || CommandLine.arguments.contains("--uitesting-corrupt-history") || CommandLine.arguments.contains("--uitesting-reset-history") {
            if let customKeyIndex = CommandLine.arguments.firstIndex(of: "--uitesting-storage-key"),
               customKeyIndex + 1 < CommandLine.arguments.count {
                activeStorageKey = CommandLine.arguments[customKeyIndex + 1]
            } else {
                activeStorageKey = UserDefaultsHistoryStore.uiTestStorageKey
            }

            if CommandLine.arguments.contains("--uitesting-corrupt-history") {
                UserDefaults.standard.set(Data("corrupted-json-payload-dlamsd02".utf8), forKey: activeStorageKey)
            } else if CommandLine.arguments.contains("--uitesting-reset-history") || !CommandLine.arguments.contains("--uitesting-preserve-history") {
                UserDefaults.standard.removeObject(forKey: activeStorageKey)
            }
        }
        let store = UserDefaultsHistoryStore(storageKey: activeStorageKey)

        var catalogDir: URL?
        if let customCatalogDirIndex = CommandLine.arguments.firstIndex(of: "--uitesting-catalog-dir"),
           customCatalogDirIndex + 1 < CommandLine.arguments.count {
            let rawPath = CommandLine.arguments[customCatalogDirIndex + 1]
            // Resolve relative directory names inside NSTemporaryDirectory so UI tests work inside physical iOS/iPadOS sandboxes.
            if rawPath.hasPrefix("/") {
                catalogDir = URL(fileURLWithPath: rawPath, isDirectory: true)
            } else {
                catalogDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    .appendingPathComponent(rawPath, isDirectory: true)
            }
        } else if CommandLine.arguments.contains("--uitesting") && !CommandLine.arguments.contains("--uitesting-preserve-catalog") {
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AssessYourselfUITestCatalog_\(ProcessInfo.processInfo.processIdentifier)", isDirectory: true)
            catalogDir = tempDir
        }
        let catalogStoreInstance = SandboxCatalogStore(baseURL: catalogDir)
        #else
        let store = UserDefaultsHistoryStore()
        let catalogStoreInstance = SandboxCatalogStore()
        #endif

        self.historyStore = store
        self.catalogStore = catalogStoreInstance
        _viewModel = StateObject(wrappedValue: AssessmentViewModel(historyStore: store, catalogStore: catalogStoreInstance))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(historyStore: store))
        _catalogManagerViewModel = StateObject(wrappedValue: CatalogManagerViewModel(catalogStore: catalogStoreInstance))
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                AssessmentFlowView(viewModel: viewModel)
                    .tabItem {
                        Label("Assessment", systemImage: "list.clipboard")
                    }
                    .tag(0)
                    .accessibilityIdentifier("tab.assessmentFlow")

                HistoryView(viewModel: historyViewModel)
                    .tabItem {
                        Label("Verlauf", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(1)
                    .accessibilityIdentifier("tab.history")

                CatalogManagerView(viewModel: catalogManagerViewModel)
                    .tabItem {
                        Label("Katalog", systemImage: "folder.badge.gearshape")
                    }
                    .tag(2)
                    .accessibilityIdentifier("tab.catalogManager")

                ComponentShowcaseView()
                    .tabItem {
                        Label("Showcase", systemImage: "square.grid.2x2")
                    }
                    .tag(3)
                    .accessibilityIdentifier("tab.showcase")
            }
            .appTheme(AppTheme.standard)
        }
    }
}
#endif
