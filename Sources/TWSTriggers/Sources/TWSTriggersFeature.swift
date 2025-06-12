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
import TWSCommon

@Reducer
public struct TWSTriggersFeature {
    @Dependency(\.api) var api
    @Dependency(\.configuration) var config

    public init() {}

    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: String
        
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
            case campaignLoaded(Result<(TWSCampaign), Error>)
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
        }
    }
    
    private func _reduce(into state: inout State, action: Action.BusinessAction) -> Effect<Action> {
        switch action {
        case .checkTrigger(let trigger):
            return .run { [api, config] send in
                do {
                    let campaign = try await api.getCampaigns(trigger)
                    
                    await send(.business(.campaignLoaded(.success((campaign)))))
                } catch {
                    await send(.business(.campaignLoaded(.failure(error))))
                }
            }
            
        case .campaignLoaded(.success(let campaign)):
            let eligibleCampaingSnippets = campaign.snippets
            var effects = [Effect<Action>]()
            
            eligibleCampaingSnippets.forEach {
                effects.append(.send(.delegate(.openOverlay($0))))
            }
            
            logger.info("Opening overlays for campaign: \(state.id)")
            
            return .merge(effects)
        case .campaignLoaded(.failure(let error)):
            logger.info("Campaign could not be loaded: \(error)")
            return .none
        default:
            return .none
        }
    }
}
