//
//  ContentView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWS

@MainActor
struct ContentView: View {

    @State private var viewModel = ContentViewModel()
    @Environment(TWSManager.self) private var twsManager
    @Environment(TWSViewModel.self) private var twsViewModel

    var body: some View {
        @Bindable var twsViewModel = twsViewModel
        return TabView(
            selection: $viewModel.tab,
            content: {
                Group {
                    SnippetsTabView()
                        .tabItem {
                            Text("Tab")
                            Image(systemName: "house")
                        }
                        .tag(ContentViewModel.Tab.fullscreenSnippets)

                    SnippetsView()
                        .tabItem {
                            Text("List")
                            Image(systemName: "list.bullet")
                        }
                        .tag(ContentViewModel.Tab.snippets)

                    SettingsView()
                        .tabItem {
                            Text("Settings")
                            Image(systemName: "gear")
                        }
                        .tag(ContentViewModel.Tab.settings)
                }
            }
        )
        .onOpenURL(perform: { url in
            twsViewModel.handleIncomingUrl(url)
        })
        // This is needed when a link is opened by scanning a QR code with the camera app.
        // In that case, the `onOpenURL` is not called.
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb, perform: { userActivity in
            guard let url = userActivity.webpageURL
            else { return }
            twsViewModel.handleIncomingUrl(url)
        })
        .sheet(item: $twsViewModel.universalLinkLoadedSnippet) {
            SingleSnippetView(snippet: $0)
        }
        .overlay {
            ZStack(alignment: .topTrailing) {
                Text("Manager state: \(twsManager.snippets.state)")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }
}
