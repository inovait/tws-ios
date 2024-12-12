//
//  SingleSnippetView.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 12. 12. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import UIKit
import SwiftUI
import TWS

struct SingleSnippetView: View {

    var snippet: TWSSnippet

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    SnippetView(snippet: snippet)
                }
                .padding()
            }
        }
    }
}

private struct SnippetView: View {

    let snippet: TWSSnippet
    @State private var info = TWSViewState()

    var body: some View {
        @Bindable var info = info

        VStack(alignment: .leading) {
            TWSView(
                snippet: snippet,
                state: $info,
                overrideVisibilty: true
            )
            .border(Color.black)
        }
    }
}
