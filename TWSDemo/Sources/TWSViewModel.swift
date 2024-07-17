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
        organizationID: "8281fd90d96b862ba9d76583007ec4b89691b39884a01aa90da5cbb3ad365690",
        projectID: "60c6988a-557e-402a-94a4-02cfb51f5728"
    ))
    var snippets: [TWSSnippet]
    var qrLoadedSnippet: TWSSnippet?

    init() {
        snippets = manager.snippets
        manager.run(listenForChanges: true)
    }

    func handleIncomingUrl(_ url: URL) {
        manager.handleIncomingUrl(url)
    }

    @MainActor
    func startupInitTasks() async {
        for await snippetEvent in self.manager.events {
            switch snippetEvent {
            case .universalLinkSnippetLoaded(let snippet):
                self.qrLoadedSnippet = snippet
            case .snippetsUpdated(let snippets):
                self.snippets = snippets
            default:
                print("Unhandled stream event")
            }
        }
    }
}
