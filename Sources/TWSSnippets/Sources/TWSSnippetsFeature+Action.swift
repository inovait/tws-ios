//
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import ComposableArchitecture
import TWSModels
import TWSSnippet
import TWSTriggers

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
            case setLocalProps(props: (TWSSnippet.ID, [String: TWSSnippet.Props]))
            case showSnippet(snippetId: TWSSnippet.ID)
            case hideSnippet(snippetId: TWSSnippet.ID)
            case sendTrigger(String)
            case trigger(IdentifiedActionOf<TWSTriggersFeature>)
            case snippets(IdentifiedActionOf<TWSSnippetFeature>)
            case campaignSnippets(IdentifiedActionOf<TWSSnippetFeature>)
        }

        @CasePathable
        public enum DelegateAction {
            case openOverlay(TWSSnippet)
            case reloadProject
        }
        case delegate(DelegateAction)
        case business(BusinessAction)
    }
}
