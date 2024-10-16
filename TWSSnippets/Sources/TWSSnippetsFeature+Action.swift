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
            case listenForChanges
            case delayReconnect
            case reconnectTriggered
            case stopListeningForChanges
            case stopReconnecting
            case isSocketConnected(Bool)
            case snippets(IdentifiedActionOf<TWSSnippetFeature>)
            case set(source: TWSSource)
        }

        case business(BusinessAction)
    }
}
