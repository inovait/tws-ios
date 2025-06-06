import SwiftUI
import TWS

@main
struct SampleApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .twsRegister(configuration: TWSBasicConfiguration(id: "<TWS_PROJECT>"))
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = .red
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor.red.withAlphaComponent(0.2)
                }
        }
    }
}
