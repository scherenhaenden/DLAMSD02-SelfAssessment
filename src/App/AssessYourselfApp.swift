import SwiftUI

#if !SWIFT_PACKAGE
@main
struct AssessYourselfApp: App {
    private let historyStore: UserDefaultsHistoryStore
    @StateObject private var viewModel: AssessmentViewModel
    @State private var selectedTab: Int = 0

    init() {
        if CommandLine.arguments.contains("--uitesting") {
            UserDefaults.standard.removeObject(forKey: UserDefaultsHistoryStore.defaultStorageKey)
        }
        let store = UserDefaultsHistoryStore()
        self.historyStore = store
        _viewModel = StateObject(wrappedValue: AssessmentViewModel(historyStore: store))
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

                HistoryView(historyStore: historyStore)
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
