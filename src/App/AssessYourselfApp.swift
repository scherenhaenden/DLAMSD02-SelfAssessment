import SwiftUI

#if !SWIFT_PACKAGE
@main
struct AssessYourselfApp: App {
    private let historyStore: UserDefaultsHistoryStore
    @StateObject private var viewModel: AssessmentViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @State private var selectedTab: Int = 0

    init() {
        if CommandLine.arguments.contains("--uitesting-corrupt-history") {
            UserDefaults.standard.set("corrupted-json-payload-dlamsd02".data(using: .utf8), forKey: UserDefaultsHistoryStore.defaultStorageKey)
        } else if CommandLine.arguments.contains("--uitesting-reset-history") || (CommandLine.arguments.contains("--uitesting") && !CommandLine.arguments.contains("--uitesting-preserve-history")) {
            UserDefaults.standard.removeObject(forKey: UserDefaultsHistoryStore.defaultStorageKey)
        }
        let store = UserDefaultsHistoryStore()
        self.historyStore = store
        _viewModel = StateObject(wrappedValue: AssessmentViewModel(historyStore: store))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(historyStore: store))
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

                ComponentShowcaseView()
                    .tabItem {
                        Label("Showcase", systemImage: "square.grid.2x2")
                    }
                    .tag(2)
                    .accessibilityIdentifier("tab.showcase")
            }
            .appTheme(AppTheme.standard)
        }
    }
}
#endif
