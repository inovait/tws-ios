//
//  ProjectViewModel.swift
//  TWS
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWS

@MainActor
@Observable
class ProjectViewModel {

    private let _id = UUID().uuidString.suffix(4)
    let manager: TWSManager
    private(set) var tabSnippets: [TWSSnippet]
    private(set) var popupSnippets: [TWSSnippet]
    let destinationID = UUID()
    var universalLinkLoadedSnippet: TWSSnippet?
    var presentPopups: Bool = false

    private var clearedPopupSnippets: [TWSSnippet] = []

    init(manager: TWSManager) {
        let snippets = manager.snippets()
        self.tabSnippets = snippets.filter(\.isTab)
        self.popupSnippets = snippets.filter { _ in
            // As of now, because `type` needs to be removed with TWS-212,
            // We have no way to detect pop-ups (Check TWSPopUpViewModel too)
            // Before: return snippet.type == .popup
            return false
        }
        self.manager = manager
        self.presentPopups = !popupSnippets.isEmpty
        // Do not call `.run()` in the initializer! SwiftUI views can recreate multiple instances of the same view.
        // Therefore, the initializer should be free of any business logic.
        // Calling `run` here will trigger a refresh, potentially causing excessive updates.
        print("INIT ->", _id, "ProjectViewModel", Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        print("DEINIT ->", _id, "ProjectViewModel")
    }

    func startupInitTasks() async {
        await manager.observe { [weak self] event in
            guard let self else { return }

            switch event {
            case let .universalLinkSnippetLoaded(project):
                print("->", _id, "Received event: universal link loaded")
                self.universalLinkLoadedSnippet = project.snippets[0]

            case .snippetsUpdated:
                print("->", _id, "Received event: snippets updated")
                let snippets = manager.snippets()
                self.tabSnippets = snippets.filter(\.isTab)
                self.popupSnippets = snippets.filter({ _ in
                    // As of now, because `type` needs to be removed with TWS-212,
                    // We have no way to detect pop-ups (Check TWSPopUpViewModel too)
                    // Before: snippet.type == .popup && self.canShowPopupSnippet(snippet)
                    return false
                })
                self.presentPopups = !self.popupSnippets.isEmpty

            case .stateChanged:
                break

            @unknown default:
                break
            }
        }

        print("->", _id, "Stopped listening")
        tabSnippets = []
        popupSnippets = []
        universalLinkLoadedSnippet = nil
    }
}
