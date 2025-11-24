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
internal import ComposableArchitecture
internal import TWSSnippet
import TWSModels

// periphery:ignore
@MainActor
class ResourceDownloadHandler {
    private var store: StoreOf<TWSSnippetFeature>? = nil
    private var cancellables = Set<AnyCancellable>()
    private var onSuccess: ((ResourceResponse?) -> Void)? = nil
    private var shouldCancel: (() -> Bool)? = nil
    private var onError: ((Error) -> Void)? = nil
    
    init() {}
    
    func loadNewStore(_ store: StoreOf<TWSSnippetFeature>, onSuccess: @escaping (ResourceResponse?) -> Void, shouldCancel: @escaping () -> Bool, onError: @escaping (Error) -> Void) {
        self.store = store
        self.onSuccess = onSuccess
        self.onError = onError
        cancellables.removeAll()
        
        store.publisher
            .map { ($0.htmlContent, $0.error) }
            .compactMap { htmlContent, error -> (htmlContent: ResourceResponse?, error: Error?)? in
                return (htmlContent: htmlContent, error: error)
            }
            .dropFirst()
            .sink { [weak self] content in
                if let err = content.error {
                    onError(err)
                } else if let html = content.htmlContent {
                    if !shouldCancel() {
                        onSuccess(html)
                    }
                }
            }
            .store(in: &cancellables)
        
        store.send(.business(.downloadContent))
    }
    
    func destroyStore() {
        self.store = nil
        self.onError = nil
        self.onSuccess = nil
        self.shouldCancel = nil
        cancellables.removeAll()
    }
    
    func cancelDownload() {
        store?.send(.business(.cancelDownload))
    }
}
