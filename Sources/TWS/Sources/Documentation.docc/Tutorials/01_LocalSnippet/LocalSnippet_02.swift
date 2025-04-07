import SwiftUI
import Foundation
import TWS

struct HomeView: View {

    var body: some View {
        ZStack {

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

        return snippet
    }
}
