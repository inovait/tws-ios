import SwiftUI
import TWS

@main
struct TWSSampleApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .twsEnable(configuration: .init(
                    organizationID: "samples",
                    projectID: "sample"
                ))
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = .red
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor.red.withAlphaComponent(0.2)
                }
        }
    }
}
