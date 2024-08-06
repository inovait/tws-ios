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
@MainActor
class TWSViewModel {

    let manager = TWSFactory.new(with: .init(
        organizationID: "357b24f6-4714-42b1-9e15-0b07cae2fcd6",
        projectID: "4166c981-56ae-4007-bc93-28875e6a2ca5"
    ))
    var snippets: [TWSSnippet]
    var universalLinkLoadedProject: LoadedProjectInfo? {
        didSet {
            print("-> did set project to: \(universalLinkLoadedProject?.manager.id)")
        }
    }
    // TODO:
    private let _id = UUID().uuidString.suffix(4)

    init() {
        snippets = manager.snippets
        // Do not call `.run()` in the initializer! SwiftUI views can recreate multiple instances of the same view.
        // Therefore, the initializer should be free of any business logic.
        // Calling `run` here will trigger a refresh, potentially causing excessive updates.
    }

    func handleIncomingUrl(_ url: URL) {
        manager.handleIncomingUrl(url)
    }

    func start() async {
        manager.run()
    }

    func startupInitTasks() async {
        print("-> [Listen]", _id, "Start")
        await manager.observe { event in
            print("-> [Listen]", self._id, "Received", event)
            switch event {
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

        print("-> [Listen]", _id, "End")
    }
}
