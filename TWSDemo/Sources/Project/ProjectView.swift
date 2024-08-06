//
//  PrrojectView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

@MainActor
struct ProjectView: View {

    @State private var viewModel: ProjectViewModel
    @State private var selectedID: UUID

    init(manager: TWSManager, selectedID: UUID) {
        _viewModel = .init(initialValue: ProjectViewModel(manager: manager))
        _selectedID = .init(initialValue: selectedID)
    }

    var body: some View {
        TabView(selection: $selectedID) {
            ForEach(viewModel.snippets) { snippet in
                ProjectSnippetView(
                    snippet: snippet,
                    manager: viewModel.manager
                )
                .tabItem { Text("\(snippet.id.uuidString.suffix(4))") }
                .tag(snippet.id)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            await viewModel.start()
            await viewModel.startupInitTasks()
        }
        .sheet(item: $viewModel.universalLinkLoadedProject) {
            ProjectView(manager: $0.manager, selectedID: $0.selectedID)
        }
    }
}
