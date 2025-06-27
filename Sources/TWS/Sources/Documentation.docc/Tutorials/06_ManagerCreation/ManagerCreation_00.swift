import SwiftUI
import TWS

struct ContentView: View {
    // Create snippet with TWSFactory
    @State var manager = TWSFactory.new(with: TWSBasicConfiguration(id: "projectId"))
    
    var body: some {
        ZStack {
            if let snippet = manager.snippets().first(where: { $0.id == "snippetId" }) {
                TWSView(snippet: snippet)
            }
        }.onAppear {
            // Register manager with remote services
            manager.registerManager()
        }
    }
}
