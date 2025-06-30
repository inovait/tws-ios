import SwiftUI
import TWS

struct ContentView: View {
    @State var manager = TWSFactory.new(with: TWSBasicConfiguration(id: "projectId"))
    var body: some View {
        HomeView()
            .twsRegister(using: manager)
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
