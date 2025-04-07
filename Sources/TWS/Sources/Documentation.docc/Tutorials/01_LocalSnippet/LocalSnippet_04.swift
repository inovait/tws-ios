import SwiftUI
import Foundation
import TWS

struct HomeView: View {

    var body: some View {
        ZStack {
            TWSView(
                snippet: localSnippet()
            )
        }
    }

    // A local instance of a snippet
    private func localSnippet() -> TWSSnippet {
        var snippet = TWSSnippet(
            id: "xyz",
            target: URL(string: "https://www.google.com")!
        )

        snippet.target = URL(string: "https://duckduckgo.com/")!

        snippet.headers = [
            "header1": "value1"
        ]

        snippet.engine = .mustache

        snippet.props = .dictionary([
            "name": .string("John"),
            "age": .int(25)
        ])

        return snippet
    }
}
