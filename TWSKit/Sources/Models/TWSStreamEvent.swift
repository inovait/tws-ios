//
//  TWSStreamEvent.swift
//  TWSKit
//
//  Created by Luka Kit on 1. 7. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import TWSModels

/// Events that are sent to ``TWSManager`` regarding updates
public enum TWSStreamEvent {
    /// This event is sent when snippet from the universal link is processed
        /// - Parameter TWSSnippet: An instance of TWSSnippet
    case universalLinkSnippetLoaded(TWSSnippet)
    
    /// This event is sent when there are new snippets available
        /// - Parameter TWSSnippets A list of new snippets
    case snippetsUpdated([TWSSnippet])
}
