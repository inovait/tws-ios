import SwiftUI
import TWS

@main
struct SampleApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .twsEnable(configuration: TWSBasicConfiguration(id: "example"))
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = .red
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor.red.withAlphaComponent(0.2)
                }
        }
    }
}
