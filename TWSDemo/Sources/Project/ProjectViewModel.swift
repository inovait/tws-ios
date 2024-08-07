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

    private let _id = UUID().uuidString.suffix(4)
    let manager: TWSManager
    private(set) var snippets: [TWSSnippet]
    var universalLinkLoadedProject: LoadedProjectInfo?

    init(manager: TWSManager) {
        self.snippets = manager.snippets
        self.manager = manager
        // Do not call `.run()` in the initializer! SwiftUI views can recreate multiple instances of the same view.
        // Therefore, the initializer should be free of any business logic.
        // Calling `run` here will trigger a refresh, potentially causing excessive updates.
        print("Project view model init", _id, Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        print("-> Project view model deinit", _id)
    }

    func start() async {
        manager.run()
    }

    func startupInitTasks() async {
        await manager.observe { [weak self] event in
            guard let self else { return }

            switch event {
            case let .universalLinkSnippetLoaded(project):
                let manager = TWSFactory.new(with: project)
                self.universalLinkLoadedProject = .init(
                    viewModel: .init(manager: manager),
                    selectedID: project.snippet.id
                )

            case let .snippetsUpdated(updatedSnippets):
                self.snippets = updatedSnippets

            @unknown default:
                break
            }
        }
    }
}
