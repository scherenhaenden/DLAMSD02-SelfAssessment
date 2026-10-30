import SwiftUI

#if !SWIFT_PACKAGE
@main
struct AssessYourselfApp: App {
    var body: some Scene {
        WindowGroup {
            ComponentShowcaseView()
                .appTheme(AppTheme.standard)
        }
    }
}
#endif
