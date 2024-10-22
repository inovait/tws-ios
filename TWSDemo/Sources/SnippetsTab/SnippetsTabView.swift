//
//  SnippetsTabView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 5. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit
import TWSModels

@MainActor
struct SnippetsTabView: View {

    @Environment(TWSViewModel.self) private var twsViewModel
    @State private var selectedId: UUID?

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    ForEach(
                        Array(zip(twsViewModel.tabSnippets.indices, twsViewModel.tabSnippets)),
                        id: \.1.id
                    ) { idx, snippet in
                        ZStack {
                            SnippetView(snippet: snippet)
                                .zIndex(Double(selectedId == snippet.id ? twsViewModel.tabSnippets.count : idx))
                                .opacity(selectedId != snippet.id ? 0 : 1)
                        }
                    }
                }

                ViewThatFits {
                    _selectionView()

                    ScrollView(.horizontal, showsIndicators: false) {
                        _selectionView()
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .onAppear {
                // Safe to force cast, because of the first segment
                guard selectedId == nil || !twsViewModel.tabSnippets.map(\.id).contains(selectedId!) else { return }
                selectedId = twsViewModel.tabSnippets.first?.id
            }
            .onChange(of: twsViewModel.tabSnippets.first?.id) { _, newValue in
                guard selectedId == nil else { return }
                selectedId = newValue
            }
        }
    }

    @ViewBuilder
    private func _selectionView() -> some View {
        if twsViewModel.tabSnippets.count > 1 {
            HStack(spacing: 1) {
                ForEach(
                    Array(zip(twsViewModel.tabSnippets.indices, twsViewModel.tabSnippets)), id: \.1.id
                ) { _, item in
                    Button {
                        selectedId = item.id
                    } label: {
                        VStack {
                            if let icon = item.props?[.tabIcon, as: \.string] {
                                Image(systemName: icon)
                                    .foregroundColor(selectedId == item.id ? Color.accentColor : Color.gray)
                            }

                            Text("\(item.props?[.tabName, as: \.string] ?? "")")
                                .foregroundColor(selectedId == item.id ? Color.accentColor : Color.gray)

                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(height: selectedId == item.id ? 1 : 0)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 1)
                        }
                        .frame(minWidth: 75, maxWidth: .infinity)
                    }
                }
            }
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
        VStack(alignment: .leading) {
            let displayId = "tab-\(snippet.id.uuidString)"

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
                displayID: "tab-\(snippet.id.uuidString)",
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .border(Color.black)
        }
    }
}
