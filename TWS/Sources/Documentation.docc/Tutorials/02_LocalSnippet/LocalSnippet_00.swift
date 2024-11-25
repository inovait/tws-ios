//
//  LocalSnippet_00.swift
//  
//
//  Created by Miha Hozjan on 25. 11. 24.
//

import SwiftUI
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

        return snippet
    }
}
