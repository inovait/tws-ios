//
//  TWSViewModel.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 30. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

@Observable
class TWSViewModel {

    let manager = TWSFactory.new(with: .init(
        organizationID: "357b24f6-4714-42b1-9e15-0b07cae2fcd6",
        projectID: "4166c981-56ae-4007-bc93-28875e6a2ca5"
    ))
    var snippets: [TWSSnippet]
    var universalLinkLoadedProject: LoadedProjectInfo?

    init() {
        snippets = manager.snippets
        // Do not call `.run()` in the initializer! SwiftUI views can recreate multiple instances of the same view.
        // Therefore, the initializer should be free of any business logic.
        // Calling `run` here will trigger a refresh, potentially causing excessive updates.
    }

    func handleIncomingUrl(_ url: URL) {
        manager.handleIncomingUrl(url)
    }

    @MainActor
    func start() async {
        manager.run()
    }

    @MainActor
    func startupInitTasks() async {
        for await snippetEvent in self.manager.events {
            switch snippetEvent {
            case let .universalLinkSnippetLoaded(project):
                self.universalLinkLoadedProject = .init(
                    manager: TWSFactory.new(with: project),
                    selectedID: project.snippet.id
                )

            case .snippetsUpdated(let snippets):
                self.snippets = snippets

            default:
                print("Unhandled stream event")
            }
        }
    }
}

struct LoadedProjectInfo: Identifiable {

    let manager: TWSManager
    let selectedID: UUID

    var id: TWSManager.ID {
        manager.id
    }
}
