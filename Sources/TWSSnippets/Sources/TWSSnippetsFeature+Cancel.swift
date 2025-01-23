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

extension TWSSnippetsFeature {

    // It is important to further differentiate cancel events with `TWSConfiguration`
    // This is because TCA uses combine pipelines, which means the same hashable value
    // could potentially leak to all active stores.
    enum CancelID: Hashable {
        case socket(String)
        case reconnect(String)
        case showSnippet(TWSSnippet.ID)
        case hideSnippet(TWSSnippet.ID)
    }
}
