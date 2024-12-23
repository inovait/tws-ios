import SwiftUI
import TWS

@main
struct TWSSampleApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .twsEnable(configuration: .init(
                    organizationID: "<TWS_ORGANIZATION>",
                    projectID: "<TWS_PROJECT>"
                ))
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = .red
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor.red.withAlphaComponent(0.2)
                }
        }
    }
}
