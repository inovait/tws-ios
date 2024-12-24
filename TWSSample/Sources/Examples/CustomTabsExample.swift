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

import SwiftUI
import TWS

struct CustomTabsExample: View {

    @Environment(TWSManager.self) var tws
    @State private var selectedTab = "customTabs"

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(
                tws.snippets()
                    .filter { Set(["customTabs", "customPages", "homePage"]).contains($0.id) }
                    .sorted(by: { customSort($0, $1) })
            ) { snippet in
                TWSView(snippet: snippet)
                    .tabItem {
                        if let title = snippet.props?[.tabName, as: \.string] {
                            Text(title)
                        }

                        if let icon = snippet.props?[.tabIcon, as: \.string] {
                            if UIImage(named: icon) != nil {
                                Image(icon)
                            } else if UIImage(systemName: icon) != nil {
                                Image(systemName: icon)
                            }
                        }
                    }
                    .tag(snippet.id)
            }
        }
    }

    private func customSort(_ lhs: TWSSnippet, _ rhs: TWSSnippet) -> Bool {
        guard
            let idxl = lhs.props?["tabSortKey"]?.int,
            let idxr = rhs.props?["tabSortKey"]?.int
        else {
            return true
        }

        return idxl < idxr
    }
}
