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

    let manager = TWSFactory.new()
    var snippets: [TWSSnippet]
    var qrLoadedSnippet: TWSSnippet?

    init() {
        snippets = manager.snippets
        manager.run(listenForChanges: true)
    }

    func handleIncomingUrl(_ url: URL) {
        manager.handleIncomingUrl(url)
    }

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
