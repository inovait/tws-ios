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

    @Environment(TWSManager.self) var twsManager
    @State private var selectedId: TWSSnippet.ID?

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    ForEach(
                        Array(zip(
                            twsManager.tabs.indices,
                            twsManager.tabs
                        )),
                        id: \.1.id
                    ) { idx, snippet in
                        ZStack {
                            SnippetView(snippet: snippet)
                                .zIndex(Double(selectedId == snippet.id ? twsManager.tabs.count : idx))
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
                guard selectedId == nil || !twsManager.tabs.map(\.id).contains(selectedId!) else { return }
                selectedId = twsManager.tabs.first?.id
            }
            .onChange(of: twsManager.tabs.first?.id) { _, newValue in
                guard selectedId == nil else { return }
                selectedId = newValue
            }
        }
    }

    @ViewBuilder
    private func _selectionView() -> some View {
        if twsManager.tabs.count > 1 {
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(
                    Array(zip(
                        twsManager.tabs.indices,
                        twsManager.tabs
                    )),
                    id: \.1.id
                ) { _, item in
                    Button {
                        selectedId = item.id
                    } label: {
                        VStack {
                            if let icon = item.props?[.tabIcon, as: \.string] {
                                Group {
                                    if UIImage(named: icon) != nil {
                                        Image(icon)
                                    } else if UIImage(systemName: icon) != nil {
                                        Image(systemName: icon)
                                    } else {
                                        Image("broken_image")
                                    }
                                }
                                .foregroundColor(selectedId == item.id ? Color.accentColor : Color.gray)
                            }

                            if let tabName = item.props?[.tabName, as: \.string] {
                                Text(tabName)
                                    .foregroundColor(selectedId == item.id ? Color.accentColor : Color.gray)
                            }

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
    @State private var info = TWSViewInfo()

    var body: some View {
        @Bindable var info = info

        VStack(alignment: .leading) {
            let displayId = "tab-\(snippet.id)"

            HStack {
                Button {
                    twsViewModel.manager.goBack(
                        snippet: snippet,
                        displayID: displayId
                    )
                } label: {
                    Image(systemName: "arrowshape.backward.fill")
                }
                .disabled(!info.canGoBack)

                Button {
                    twsViewModel.manager.goForward(
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
                displayID: "tab-\(snippet.id)",
                info: $info
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .border(Color.black)
        }
    }
}
