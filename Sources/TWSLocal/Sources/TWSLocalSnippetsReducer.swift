////
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

@Reducer
struct TWSLocalSnippetsReducer: Equatable {
    
    @ObservableState
    struct State: Equatable {
        #if TESTING
        // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
        var snippets: IdentifiedArrayOf<TWSSnippetFeature.State> = .init()
        #else
        @Shared(.inMemory("snippets")) var snippets: IdentifiedArrayOf<TWSSnippetFeature.State> = .init()
        #endif
        public nonisolated init() {}
    }
    
    enum Action {
        
        @CasePathable
        enum BusinessAction {
            case saveLocalSnippet(TWSSnippet)
            case snippetAction(IdentifiedActionOf<TWSSnippetFeature>)
        }
        
        
        case business(BusinessAction)
    }
    
    var body : some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .business(let action):
                return _reduce(into: &state, action: action)
            }
        }.forEach(\.snippets, action: \.business.snippetAction) {
            TWSSnippetFeature()
        }
    }
        
    
    private func _reduce(into state: inout State, action: Action.BusinessAction) -> Effect<Action> {
        switch action {
        case .saveLocalSnippet(let snippet):
            #if TESTING
            state.snippets.append(.init(snippet: snippet))
            #else
            state.$snippets.withLock { $0.append(.init(snippet: snippet)) }
            #endif
        
        case .snippetAction(.element(id: _, action: .delegate(let delegateAction))):
            switch delegateAction {
            case .openOverlay:
                return .none
            }
        case .snippetAction:
            break
        }
        return .none
    }
}
