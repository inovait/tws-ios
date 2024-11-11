//
//  TWSViewModel.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 30. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

@MainActor
@Observable
class TWSViewModel {

    let manager = TWSFactory.new(
        with: .init(
            organizationID: "inova.tws",
            projectID: "4166c981-56ae-4007-bc93-28875e6a2ca5"
        )
    )
    let destinationID = UUID()
    var tabSnippets: [TWSSnippet]
    var popupSnippets: [TWSSnippet]
    var universalLinkLoadedProject: LoadedProjectInfo?
    var presentPopups: Bool = false

    private var clearedPopupSnippets: [TWSSnippet] = []

    init() {
        let snippets = manager.snippets
        self.tabSnippets = snippets.filter(\.isTab)
        self.popupSnippets = snippets.filter { _ in
            // As of now, because `type` needs to be removed with TWS-212,
            // We have no way to detect pop-ups (Check TWSPopUpViewModel too)
            // Before: return snippet.type == .popup
            return false
        }
        self.presentPopups = !popupSnippets.isEmpty
        // Do not call `.run()` in the initializer! SwiftUI views can recreate multiple instances of the same view.
        // Therefore, the initializer should be free of any business logic.
        // Calling `run` here will trigger a refresh, potentially causing excessive updates.
    }

    func handleIncomingUrl(_ url: URL) {
        manager.handleIncomingUrl(url)
    }

    func startupInitTasks() async {
        await manager.observe { [weak self] event in
            guard let self else { return }

            switch event {
            case let .universalLinkSnippetLoaded(project):
                self.universalLinkLoadedProject = .init(
                    viewID: destinationID,
                    configuration: project.configuration,
                    viewModel: .init(manager: TWSFactory.new(with: project)),
                    selectedID: project.snippet.id
                )

            case .snippetsUpdated:
                let snippets = manager.snippets
                self.tabSnippets = snippets.filter(\.isTab)
                self.popupSnippets = snippets.filter({ _ in
                    // As of now, because `type` needs to be removed with TWS-212,
                    // We have no way to detect pop-ups (Check TWSPopUpViewModel too)
                    // Before: return snippet.type == .popup
                    //    && self.canShowPopupSnippet(snippet)

                    return false
                })
                self.presentPopups = !self.popupSnippets.isEmpty

            default:
                assertionFailure("Unhandled stream event")
            }
        }
    }
}
