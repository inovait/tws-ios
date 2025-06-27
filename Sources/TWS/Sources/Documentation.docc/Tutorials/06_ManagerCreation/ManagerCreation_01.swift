import SwiftUI
import TWS

struct ContentView: View {
    var body: some View {
        HomeView()
            .twsRegister(configuration: TWSBasicConfiguration(id: "projectId"))
    }
}

struct HomeView: View {
    @Environment(TWSManager.self) var manager
    var body: some View {
        ZStack {
            if let snippet = manager.snippets().first(where: { $0.id == "snippetId" }) {
                TWSView(snippet: snippet)
            }
        }
    }
}
