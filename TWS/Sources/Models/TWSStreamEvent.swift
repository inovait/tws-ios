//
//  TWSStreamEvent.swift
//  TWS
//
//  Created by Luka Kit on 1. 7. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import TWSModels

/// Events that are sent to ``TWSManager`` regarding updates
public enum TWSStreamEvent: Sendable {

    /// This event is sent when a project from the universal link is processed
    /// - Parameter TWSSharedSnippetBundle: A snippet that should be preselected (opened) along with organization and project info
    case universalLinkSnippetLoaded(TWSSharedSnippet)

    /// This event is sent when there are new snippets available
    case snippetsUpdated

    /// This event is triggered when there is a change in the snippet loading state.
    case stateChanged
}
