//
//  PrrojectView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

struct ProjectView: View {

    @State private var viewModel: ProjectViewModel
    @State private var pageTitle: String = ""
    @State private var selectedID: UUID
    @Environment(\.dismiss) var dismiss

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
    }
}

@Observable
class ProjectViewModel {

    var snippets: [TWSSnippet]
    let manager: TWSManager

    init(manager: TWSManager) {
        self.snippets = manager.snippets
        self.manager = manager
        // Do not call `.run()` in the initializer! SwiftUI views can recreate multiple instances of the same view.
        // Therefore, the initializer should be free of any business logic.
        // Calling `run` here will trigger a refresh, potentially causing excessive updates.
    }

    @MainActor
    func start() async {
        manager.run()
    }

    @MainActor
    func startupInitTasks() async {
        for await snippetEvent in self.manager.events {
            switch snippetEvent {
            case .universalLinkSnippetLoaded:
                break

            case .snippetsUpdated(let snippets):
                self.snippets = snippets

            default:
                print("Unhandled stream event")
            }
        }
    }
}
