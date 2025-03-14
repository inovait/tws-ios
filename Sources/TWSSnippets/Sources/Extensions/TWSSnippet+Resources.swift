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
@_spi(Internals) import TWSModels

extension TWSSnippet {

    @MainActor
    func hasResources(for configuration: any TWSConfiguration) -> Bool {
        var headers = [Attachment: [String: String]]()
        let preloaded = SharedReader(wrappedValue: [:], .resources(for: configuration))
        let attachments = self.allResources(headers: &headers)
        return attachments.allSatisfy { preloaded[$0].wrappedValue != nil }
    }
}
