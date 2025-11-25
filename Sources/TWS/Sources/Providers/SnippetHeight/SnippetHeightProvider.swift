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

import UIKit

@MainActor
protocol SnippetHeightProvider {

    func set(height: CGFloat, for hash: WebPageDescription, displayID: String)
    func getHeight(for hash: WebPageDescription, displayID: String) -> CGFloat?
}

class SnippetHeightProviderImpl: SnippetHeightProvider {

    private var store = [WebPageDescription: [String: CGFloat]]()

    // MARK: - Confirming to `SnippetHeightProvider`

    func set(height: CGFloat, for hash: WebPageDescription, displayID: String) {
        store[hash, default: [:]][displayID] = height
    }

    func getHeight(for hash: WebPageDescription, displayID: String) -> CGFloat? {
        return store[hash]?[displayID]
    }
}
