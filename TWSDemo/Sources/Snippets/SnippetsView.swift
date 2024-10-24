//
//  SnippetsView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit
import SwiftUI
import TWSKit

struct SnippetsView: View {

    @Environment(TWSManager.self) var twsManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(twsManager.snippets.filter(\.isTab)) { snippet in
                        SnippetView(snippet: snippet)
                    }
                }
                .padding()
            }
            .navigationTitle("Snippets")
        }
    }
}

private struct SnippetView: View {

    let snippet: TWSSnippet
    @Environment(TWSManager.self) var twsManager
    @State private var info = TWSViewInfo()

    var body: some View {
        @Bindable var info = info
        let displayId = "list-\(snippet.id.uuidString)"

        VStack(alignment: .leading) {
            HStack {
                Button {
                    twsManager.goBack(
                        snippet: snippet,
                        displayID: displayId
                    )
                } label: {
                    Image(systemName: "arrowshape.backward.fill")
                }
                .disabled(!info.canGoBack)

                Button {
                    twsManager.goForward(
                        snippet: snippet,
                        displayID: displayId
                    )
                } label: {
                    Image(systemName: "arrowshape.forward.fill")
                }
                .disabled(!info.canGoForward)
            }

            Divider()

            TWSView(
                snippet: snippet,
                displayID: displayId,
                info: $info
            )
            .border(Color.black)
        }
    }
}
