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
import TWSModels
import TWSSnippet
import ComposableArchitecture


@MainActor
@Observable
public final class TWSLocalSnippetsManager {
    static var shared = StoreOf<TWSLocalSnippetsReducer>(initialState: TWSLocalSnippetsReducer.State(), reducer: { TWSLocalSnippetsReducer() })
    
    public static func getPreloadedResources() -> [TWSSnippet.Attachment: ResourceResponse] {
        return shared.state.preloadedResources
    }
    
    public static func saveLocalSnippet(_ snippet: TWSSnippet) {
        shared.send(.business(.saveLocalSnippet(snippet)))
    }
    
    public static func store(for id: TWSSnippet.ID) -> StoreOf<TWSSnippetFeature>? {
        shared.scope(
            state: \.snippets[id: id],
            action: \.business.snippetAction[id: id]
        )
    }
}
