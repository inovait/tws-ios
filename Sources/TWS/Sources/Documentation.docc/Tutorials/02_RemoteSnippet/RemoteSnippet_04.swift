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

    @Environment(TWSManager.self) var tws

    var  body: some View {
        TabView {

        }
        .twsRegisterManager(manager: tws)
    }
}
