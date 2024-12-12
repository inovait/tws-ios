//
//  PrrojectView.swift
//  TWS
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWS

@MainActor
struct ProjectView: View {

    @State private var viewModel: ProjectViewModel
    @State private var selectedID: TWSSnippet.ID

    init(viewModel: ProjectViewModel, selectedID: TWSSnippet.ID) {
        _viewModel = .init(initialValue: viewModel)
        _selectedID = .init(initialValue: selectedID)
    }

    var body: some View {
        TabView(selection: $selectedID) {
            ForEach(viewModel.tabSnippets) { snippet in
                ProjectSnippetView(
                    snippet: snippet
                )
                .tabItem {
                    if let tabName = snippet.props?[.tabName, as: \.string] {
                        Text(tabName)
                    }

                    if let icon = snippet.props?[.tabIcon, as: \.string] {
                        Image(systemName: icon)
                    }
                }
                .tag(snippet.id)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            await viewModel.startupInitTasks()
        }
        .sheet(item: $viewModel.universalLinkLoadedSnippet) {
            SingleSnippetView(snippet: $0)
        }
    }
}
