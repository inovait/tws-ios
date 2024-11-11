//
//  TWSTabView.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 7. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

public struct TWSTabView: View {

    let showTWSList: Bool
    @Environment(TWSManager.self) private var twsManager

    public init(showTWSList: Bool = true) {
        self.showTWSList = showTWSList
    }

    public var body: some View {
        TabView {
            ForEach(twsManager.tabs) { snippet in
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
                            } else {
                                Image("broken_image")
                            }
                        }
                    }
            }

            if showTWSList {
                TWSListView()
                    .tabItem {
                        Text("Preview")
                    }
            }
        }
        .mask {
            Rectangle().ignoresSafeArea(.all, edges: .bottom)
        }
    }
}
