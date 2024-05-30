//
//  ContentView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSModels

struct ContentView: View {

    @State private var viewModel = ContentViewModel()

    var body: some View {
        TabView(
            selection: $viewModel.tab,
            content: {
                SnippetsView()
                    .tabItem {
                        Text("Snippets")
                        Image(systemName: "list.star")
                    }
                    .tag(ContentViewModel.Tab.snippets)

                SettingsView()
                    .tabItem {
                        Text("Settings")
                        Image(systemName: "gear")
                    }
                    .tag(ContentViewModel.Tab.settings)
            }
        )
    }
}
