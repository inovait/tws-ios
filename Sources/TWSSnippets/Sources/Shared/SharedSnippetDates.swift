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
import TWSModels
import ComposableArchitecture
import Sharing

private extension URL {
    static func snippetDates(for config: any TWSConfiguration) -> URL {
        .documentsDirectory
        .appendingPathComponent(cacheFolder)
        .appending(component: "\(config.id)_snippets_dates.json")
    }
}


extension SharedKey where Self == Sharing.FileStorageKey<[TWSSnippet.ID: SnippetDateInfo]>.Default {
    static func snippetDates(for config: any TWSConfiguration) -> Self {
        Self[.fileStorage(.snippetDates(for: config)), default: [:]]
    }
}
