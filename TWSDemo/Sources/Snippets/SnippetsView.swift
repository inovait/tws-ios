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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(twsManager.snippets) { snippet in
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
