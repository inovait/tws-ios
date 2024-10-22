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

    @Environment(TWSViewModel.self) private var twsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(twsViewModel.tabSnippets) { snippet in
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
    @Environment(TWSViewModel.self) private var twsViewModel
    @State private var loadingState: TWSLoadingState = .idle
    @State private var canGoBack = false
    @State private var canGoForward = false

    var body: some View {
        let displayId = "list-\(snippet.id.uuidString)"

        VStack(alignment: .leading) {
            HStack {
                Button {
                    twsViewModel.manager.goBack(
                        snippet: snippet,
                        displayID: displayId
                    )
                } label: {
                    Image(systemName: "arrowshape.backward.fill")
                }
                .disabled(!canGoBack)

                Button {
                    twsViewModel.manager.goForward(
                        snippet: snippet,
                        displayID: displayId
                    )
                } label: {
                    Image(systemName: "arrowshape.forward.fill")
                }
                .disabled(!canGoForward)
            }

            Divider()

            TWSView(
                snippet: snippet,
                displayID: displayId,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                loadingState: $loadingState,
                loadingView: {
                    WebViewLoadingView()
                },
                errorView: { error in
                    WebViewErrorView(error: error)
                }
            )
            .border(Color.black)
        }
    }
}
