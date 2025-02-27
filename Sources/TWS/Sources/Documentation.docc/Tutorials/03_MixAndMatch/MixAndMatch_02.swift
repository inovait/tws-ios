import SwiftUI
import TWS

struct HomeView: View {

    @Environment(TWSManager.self) var tws

    var  body: some View {
        TabView {
            ForEach(tws.snippets()) { snippet in
                RemoteSnippetTab(snippet: snippet)
            }
        }
    }
}

struct RemoteSnippetTab: View {

    let snippet: TWSSnippet

    var body: some View {
        VStack {
            TWSView(snippet: snippet)

            DevelopmentView(id: snippet.id)
        }
    }
}

struct DevelopmentView: View {

    let id: String

    var body: some View {
        TWSView(
            // A local snippet
            snippet: .init(
                id: id,
                target: URL(string: "https://dev.tws.io?id=\(id)")
            )
        )
    }
}
