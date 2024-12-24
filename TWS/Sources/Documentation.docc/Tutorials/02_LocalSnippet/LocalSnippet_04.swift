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
import TWS

struct HomeView: View {

    var body: some View {
        ZStack {
            SnippetView(
                snippet: localSnippet()
            )
        }
    }

    // A local instance of a snippet
    private func localSnippet() -> TWSSnippet {
        var snippet = TWSSnippet(
            id: "xyz",
            target: URL(string: "https://www.google.com")!
        )

        snippet.target = URL(string: "https://duckduckgo.com/")!

        snippet.headers = [
            "header1": "value1"
        ]

        snippet.engine = .mustache

        snippet.props = .dictionary([
            "name": .string("John"),
            "age": .int(25)
        ])

        return snippet
    }
}
