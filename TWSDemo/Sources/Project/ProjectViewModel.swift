//
//  ProjectViewModel.swift
//  TWSKit
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSKit

@MainActor
@Observable
class ProjectViewModel {

    let manager: TWSManager
    var snippets: [TWSSnippet]
    var universalLinkLoadedProject: LoadedProjectInfo?

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
        await manager.observe { event in
            switch event {
            case let .universalLinkSnippetLoaded(project):
                let manager = TWSFactory.new(with: project)
                self.universalLinkLoadedProject = .init(manager: manager, selectedID: project.snippet.id)

            case .snippetsUpdated(let snippets):
                self.snippets = snippets

            @unknown default:
                break
            }
        }
    }
}
