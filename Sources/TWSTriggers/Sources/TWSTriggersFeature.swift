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
public struct TWSTriggersFeature {
    @Dependency(\.api) var api
    @Dependency(\.configuration) var config

    public init() {}

    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: String
        public var snippets: IdentifiedArrayOf<TWSSnippetFeature.State> = []
        
        public init(trigger: String) {
            self.id = trigger
        }
    }
    
    public enum Action {
        
        @CasePathable
        public enum DelegateAction {
            case openOverlay(TWSSnippet)
        }
        
        @CasePathable
        public enum BusinessAction {
            case checkTrigger(String)
            case campaignLoaded(Result<(String, TWSCampaign), Error>)
            case snippets(IdentifiedActionOf<TWSSnippetFeature>)
        }
        
        case delegate(DelegateAction)
        case business(BusinessAction)
    }
    
    public var body : some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .business(let action):
                return _reduce(into: &state, action: action)
                
            case .delegate:
                return .none
            }
        }.forEach(\.snippets, action: \.business.snippets) {
            TWSSnippetFeature()
        }
    }
    
    private func _reduce(into state: inout State, action: Action.BusinessAction) -> Effect<Action> {
        switch action {
        case .checkTrigger(let trigger):
            return .run { [api, config] send in
                do {
                    let campaign = try await api.getCampaigns(trigger)

                    await send(.business(.campaignLoaded(.success((trigger, campaign)))))
                } catch {
                    await send(.business(.campaignLoaded(.failure(error))))
                }
            }
            
        case .campaignLoaded(.success(let campaign)):
            let campaignTrigger = campaign.0
            
            let campaignSnippets: [TWSSnippetFeature.State] = campaign.1.snippets.map { .init(snippet: $0)}
            state.snippets = .init(uniqueElements: campaignSnippets)
            
            var effects = [Effect<Action>]()
            
            state.snippets.forEach {
                effects.append(.send(.business(.snippets(.element(id: $0.id, action: .view(.openCampaign))))))
            }
            logger.info("Campaign for trigger \(campaignTrigger) loaded succesfully: \(campaignSnippets)")
            
            return .merge(effects)
        case .campaignLoaded(.failure(let error)):
            logger.info("Campaign could not be loaded: \(error)")
            return .none
            
        case .snippets(.element(id: _, action: .delegate(.openOverlay(let snippet)))):
            return .send(.delegate(.openOverlay(snippet)))
        default:
            return .none
        }
    }
    
    private func _reduce(into state: inout State, action: Action.DelegateAction) -> Effect<Action> {
        return .none
    }
}
