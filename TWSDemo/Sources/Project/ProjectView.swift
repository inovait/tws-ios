//
//  PrrojectView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit
import TWSUI

@MainActor
struct ProjectView: View {

    @State private var viewModel: ProjectViewModel
    @State private var selectedID: UUID

    init(viewModel: ProjectViewModel, selectedID: UUID) {
        _viewModel = .init(initialValue: viewModel)
        _selectedID = .init(initialValue: selectedID)
    }

    var body: some View {
        TabView(selection: $selectedID) {
            ForEach(viewModel.tabSnippets) { snippet in
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
            ProjectView(viewModel: $0.viewModel, selectedID: $0.selectedID)
        }
        .fullScreenCover(isPresented: $viewModel.presentPopups, content: {
            TWSPopupView(manager: viewModel.manager)
        })
    }
}
