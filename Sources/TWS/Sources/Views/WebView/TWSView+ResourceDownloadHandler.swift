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
import Combine
@_spi(Internals) import TWSModels
internal import ComposableArchitecture
internal import TWSSnippet

@MainActor
class ResourceDownloadHandler {
    private var store: StoreOf<TWSSnippetFeature>? = nil
    private var cancellables = Set<AnyCancellable>()
    private var onSuccess: ((String?) -> Void)? = nil
    
    init() {}
    
    func loadNewStore(_ store: StoreOf<TWSSnippetFeature>, onSuccess: @escaping (String?) -> Void) {
        print("[svenk] loadNewStore called")
        self.store = store
        self.onSuccess = onSuccess
        cancellables.removeAll()
        
        store.publisher
            .map { $0.htmlContent }
            .removeDuplicates()
            .sink { [weak self] content in
                print("[svenk] new content from publisher")
                onSuccess(content)
            }
            .store(in: &cancellables)
        
        store.send(.business(.preload))
    }
}
