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

struct HomeView: View {

    var  body: some View {
        TabView {

        }
    }
}
