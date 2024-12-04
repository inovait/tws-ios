//
//  CustomTabsExample.swift
//  TheWebSnippet
//
//  Created by Miha Hozjan on 2. 12. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
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
