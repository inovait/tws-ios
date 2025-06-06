import SwiftUI
import TWS

@main
struct TWSDemoApp: App {

    var body: some Scene {
        WindowGroup {
            HomeView()
                .twsRegister(configuration: TWSBasicConfiguration(
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
