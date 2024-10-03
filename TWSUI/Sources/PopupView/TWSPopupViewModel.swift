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
    var navigation: [TWSNavigationType] {
        didSet {
            if let topNavigation = navigation.last,
            let pendingIndex = pendingNavigationRemoval.firstIndex(of: topNavigation) {
                pendingNavigationRemoval.remove(at: pendingIndex)
                navigation.removeLast()
            }
        }
    }
    let manager: TWSManager
    private var pendingNavigationRemoval: [TWSNavigationType] = []

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
                    return self.manager.canShowPopupSnippet(snippet) &&
                        TWSSnippet.SnippetType(snippetType: snippet.type) == .popup
                })
                updatedPopupSnippets.forEach { snippet in
                    if self.isPopupMissingFromTheNavigationQueue(snippet) {
                        self.addNavigationToQueue(.snippetPopup(snippet))
                    }
                }
                self.navigation.forEach { navigation in
                    if self.isNavigationMissingFromReceivedPopups(updatedPopupSnippets, navigation) {
                        self.removeNavigationFromQueue(navigation)
                    }
                }

            default:
                return
            }
        }
    }

    func removeNavigationFromQueue(_ navigation: TWSNavigationType) {
        if let index = self.navigation.firstIndex(of: navigation) {
            if index == self.navigation.endIndex - 1 {
                self.navigation.remove(at: index)
            } else {
                pendingNavigationRemoval.append(navigation)
            }
        }
    }

    private func addNavigationToQueue(_ navigation: TWSNavigationType) {
        self.navigation.append(navigation)
    }

    private func isPopupMissingFromTheNavigationQueue(_ snippet: TWSSnippet) -> Bool {
        if self.navigation.firstIndex(of: .snippetPopup(snippet)) != nil {
            return false
        }
        return true
    }

    private func isNavigationMissingFromReceivedPopups(
        _ receivedSnippets: [TWSSnippet],
        _ navigation: TWSNavigationType
    ) -> Bool {
        switch navigation {
        case .snippetPopup(let navigationSnippet):
            if receivedSnippets.firstIndex(of: navigationSnippet) != nil {
                return false
            }
        }
        return true
    }
}
