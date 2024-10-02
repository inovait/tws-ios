//
//  TWSPopupViewModel.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 30. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import Foundation
import TWSModels
import TWSKit

@Observable
class TWSPopupViewModel {
    var navigation: [TWSNavigationType]
    let manager: TWSManager

    init(manager: TWSManager) {
        self.manager = manager
        self.navigation = []
    }

    @MainActor
    func fillInitialNavigation() {
        self.navigation = manager.popupSnippets.map { .snippetPopup($0) }
    }

    func startListeningForEvents() async {
        await manager.observe { [weak self] event in
            guard let self else { return }

            switch event {
            case .snippetsUpdated(let snippets):
                let updatedPopupSnippets = snippets.filter({ snippet in
                    return self.manager.canShowPopupSnippet(snippet) && TWSSnippet.SnippetType(snippetType: snippet.type) == .popup
                })
                updatedPopupSnippets.forEach { snippet in
                    if self.isPopupMissingFromTheNavigationQueue(snippet) {
                        self.addNavigationToQueue(.snippetPopup(snippet))
                    }
                }

            default:
                return
            }
        }
    }
    
    func removeNavigationFromQueue(_ navigation: TWSNavigationType) {
        if let index = self.navigation.firstIndex(of: navigation) {
            self.navigation.remove(at: index)
        }
    }

    private func addNavigationToQueue(_ navigation: TWSNavigationType) {
        self.navigation.append(navigation)
    }

    private func isPopupMissingFromTheNavigationQueue(_ snippet: TWSSnippet) -> Bool {
        if let _ = self.navigation.firstIndex(of: .snippetPopup(snippet)) {
            return false
        }
        return true
    }
}
