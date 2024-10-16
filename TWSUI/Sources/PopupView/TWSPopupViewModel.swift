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
import SwiftUI

@MainActor
@Observable
class TWSPopupViewModel {
    var navigation: [TWSNavigationType] {
        didSet {
            if let topNavigation = navigation.last,
            let pendingIndex = pendingNavigationRemoval.firstIndex(of: topNavigation) {
                pendingNavigationRemoval.remove(at: pendingIndex)
                navigation.removeLast()
            }
            if navigation.isEmpty {
                onNavigationCleared?()
            }
        }
    }
    let manager: TWSManager
    var onNavigationCleared: (() -> Void)?

    private var clearedPopupSnippets: [TWSSnippet] = []
    private var pendingNavigationRemoval: [TWSNavigationType] = []

    init(manager: TWSManager) {
        self.manager = manager
        self.navigation = []
    }

    func addOnNavigationCleared(onNavigationCleared: @escaping (() -> Void)) {
        self.onNavigationCleared = onNavigationCleared
    }

    func fillInitialNavigation() {
        let popupSnippets = manager.snippets.filter { snippet in
            return snippet.type == .popup
        }
        self.navigation = popupSnippets.map { .snippetPopup($0) }
    }

    func startListeningForEvents() async {
        await manager.observe { [weak self] event in
            guard let self else { return }

            switch event {
            case .snippetsUpdated:
                let snippets = manager.snippets
                let updatedPopupSnippets = snippets.filter({ snippet in
                    return self.canShowPopupSnippet(snippet) && snippet.type == .popup
                })
                updatedPopupSnippets.forEach { snippet in
                    if !self.isPopupPresentInTheNavigationQueue(snippet) {
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

    public func addClearedPopup(_ snippet: TWSSnippet) {
        self.clearedPopupSnippets.append(snippet)
    }

    public func canShowPopupSnippet(_ snippet: TWSSnippet) -> Bool {
        return !clearedPopupSnippets.contains(snippet)
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

    private func isPopupPresentInTheNavigationQueue(_ snippet: TWSSnippet) -> Bool {
        var isPresent: Bool = false
        self.navigation.forEach { nav in
            switch nav {
            case .snippetPopup(let navigationSnippet):
                if navigationSnippet.id == snippet.id {
                    isPresent = true
                }
            }
        }
        return isPresent
    }

    private func isNavigationMissingFromReceivedPopups(
        _ receivedSnippets: [TWSSnippet],
        _ navigation: TWSNavigationType
    ) -> Bool {
        var isMissing = true
        switch navigation {
        case .snippetPopup(let navigationSnippet):
            receivedSnippets.forEach { snippet in
                if snippet.id == navigationSnippet.id {
                    isMissing = false
                }
            }
        }
        return isMissing
    }
}
