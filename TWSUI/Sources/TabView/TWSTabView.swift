//
//  TWSTabView.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 7. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

public struct TWSTabView<AdditionalTabs: View>: View {

    let additionalTabs: () -> AdditionalTabs
    @Environment(TWSManager.self) private var twsManager

    public init(@ViewBuilder additionalTabs: @escaping () -> AdditionalTabs) {
            self.additionalTabs = additionalTabs
        }

    public var body: some View {
        TabView {
            ForEach(twsManager.tabs) { snippet in
                TWSView(
                    snippet: snippet,
                    displayID: "home-\(snippet.id)"
                )
                .tabItem {
                    if let title = snippet.props?[.tabName, as: \.string] {
                        Text(title)
                    }

                    if let icon = snippet.props?[.tabIcon, as: \.string] {
                        if UIImage(named: icon) != nil {
                            Image(icon)
                        } else if UIImage(systemName: icon) != nil {
                            Image(systemName: icon)
                        } else {
                            Image("broken_image")
                        }
                    }
                }
            }

            additionalTabs()
        }
        .mask {
            Rectangle().ignoresSafeArea(.all, edges: .bottom)
        }
    }
}
