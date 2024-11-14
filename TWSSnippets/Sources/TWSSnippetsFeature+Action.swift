//
//  TWSSnippetsFeature+Action.swift
//  TWSSnippets
//
//  Created by Miha Hozjan on 30. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import ComposableArchitecture
import TWSModels
import TWSSnippet

extension TWSSnippetsFeature {

    @CasePathable
    public enum Action {

        @CasePathable
        public enum BusinessAction {
            case load
            case projectLoaded(Result<TWSProjectBundle, Error>)
            case startVisibilityTimers([TWSSnippet])
            case listenForChanges
            case delayReconnect
            case reconnectTriggered
            case stopListeningForChanges
            case stopReconnecting
            case isSocketConnected(Bool)
            case snippets(IdentifiedActionOf<TWSSnippetFeature>)
            case setLocalProps(props: (TWSSnippet.ID, [String: TWSSnippet.Props]))
            case showSnippet(snippetId: TWSSnippet.ID)
            case hideSnippet(snippetId: TWSSnippet.ID)
        }

        case business(BusinessAction)
    }
}
