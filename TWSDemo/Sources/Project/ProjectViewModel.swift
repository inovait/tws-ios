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
        print("INIT ->", _id, "ProjectViewModel", Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        print("DEINIT ->", _id, "ProjectViewModel")
    }

    func start() async {
        manager.run()
    }

    func startupInitTasks() async {
        await manager.observe { [weak self] event in
            guard let self else { return }

            switch event {
            case let .universalLinkSnippetLoaded(project):
                print("->", _id, "Received event: universal link loaded")
                let manager = TWSFactory.new(with: project)
                self.universalLinkLoadedProject = .init(
                    viewModel: .init(manager: manager),
                    selectedID: project.snippet.id
                )

            case let .snippetsUpdated(updatedSnippets):
                print("->", _id, "Received event: snippets updated")
                self.snippets = updatedSnippets

            @unknown default:
                break
            }
        }

        print("->", _id, "Stopped listening")
        snippets = []
        universalLinkLoadedProject = nil
    }
}
