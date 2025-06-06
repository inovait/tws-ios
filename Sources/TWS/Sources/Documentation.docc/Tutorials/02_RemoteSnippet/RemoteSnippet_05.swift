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

    @Environment(TWSManager.self) var tws

    var  body: some View {
        TabView {
            ForEach(tws.snippets()) { snippet in

            }
        }
    }
}
