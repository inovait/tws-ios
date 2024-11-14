//
//  SnippetsView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit
import SwiftUI
import TWS

struct SnippetsView: View {

    @Environment(TWSManager.self) var twsManager
    @AppStorage(Source.key) private var source: Source = .server

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(_snippets) { snippet in
                        SnippetView(snippet: snippet)
                            .twsLocal(source != .server)
                    }
                }
                .padding()
            }
            .navigationTitle("Snippets")
        }
    }

    private var _snippets: [TWSSnippet] {
        switch source.type {
        case .server:
            return twsManager.tabs

        case let .local(urls):
            var id = 0
            var snippets: [TWSSnippet] = []
            urls.forEach {
                snippets.append(
                    .init(
                        id: "\(id)-\($0.absoluteString)",
                        target: $0
                    )
                )

                id += 1
            }

            return snippets
        }
    }
}

private struct SnippetView: View {

    let snippet: TWSSnippet
    @State private var info = TWSViewInfo()
    @State private var navigator = TWSViewNavigator()

    var body: some View {
        @Bindable var info = info

        VStack(alignment: .leading) {
            HStack {
                Button {
                    navigator.goBack()
                } label: {
                    Image(systemName: "arrowshape.backward.fill")
                }
                .disabled(!navigator.canGoBack)

                Button {
                    navigator.goForward()
                } label: {
                    Image(systemName: "arrowshape.forward.fill")
                }
                .disabled(!navigator.canGoForward)

                Button {
                    navigator.reload()
                } label: {
                    Image(systemName: "repeat")
                }
            }

            Divider()

            TWSView(
                snippet: snippet,
                info: $info
            )
            .border(Color.black)
        }
        .twsBind(navigator: navigator)
    }
}
