//
//  TWSViewModel.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 30. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSModels
import TWSKit

@Observable
class TWSViewModel {

    let manager = TWSFactory.new()
    var snippets: [TWSSnippet]
    var qrLoadedSnippet: TWSSnippet?

    init() {
        snippets = manager.snippets
        qrLoadedSnippet = manager.qrLoadedSnippet

        manager.run(listenForChanges: true)
    }

    public func handleIncomingUrl(_ url: URL) {
        manager.handleIncomingUrl(url)
    }

    public func startupInitTasks() async {
        await withDiscardingTaskGroup { group in
            group.addTask { [self] in
                for await snippets in self.manager.snippetsStream {
                    self.snippets = snippets
                }
            }
            group.addTask { [self] in
                for await snippet in self.manager.qrSnippetStream {
                    self.qrLoadedSnippet = snippet
                }
            }
        }
    }
}
