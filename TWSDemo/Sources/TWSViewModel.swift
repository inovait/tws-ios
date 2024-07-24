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
    var qrLoadedSnippet: TWSSnippet?

    init() {
        snippets = manager.snippets
        manager.run()
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
