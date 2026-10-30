import SwiftUI

#if !SWIFT_PACKAGE
@main
struct AssessYourselfApp: App {
    @StateObject private var viewModel = AssessmentViewModel()
    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                AssessmentFlowView(viewModel: viewModel)
                    .tabItem {
                        Label("Assessment", systemImage: "list.clipboard")
                    }
                    .tag(0)
                    .accessibilityIdentifier("tab.assessmentFlow")

                ComponentShowcaseView()
                    .tabItem {
                        Label("Showcase", systemImage: "square.grid.2x2")
                    }
                    .tag(1)
                    .accessibilityIdentifier("tab.showcase")
            }
            .appTheme(AppTheme.standard)
        }
    }
}
#endif
