import SwiftUI
import TWS

@main
struct TWSDemoApp: App {

    var body: some Scene {
        WindowGroup {
            HomeView()
                .twsSetManager(configuration: TWSBasicConfiguration(
                    id: "<PROJECT_ID>"
                ))
        }
    }
}
