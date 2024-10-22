//
//  ContentView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSUI

@MainActor
struct ContentView: View {

    @State private var viewModel = ContentViewModel()
    @Environment(TWSViewModel.self) private var twsViewModel

    var body: some View {
        @Bindable var twsViewModel = twsViewModel
        return TabView(
            selection: $viewModel.tab,
            content: {
                SnippetsTabView()
                    .tabItem {
                        Text("Tab")
                        Image(systemName: "house")
                    }
                    .tag(ContentViewModel.Tab.fullscreenSnippets)
                    .twsEnable(using: twsViewModel.manager)

                SnippetsView()
                    .tabItem {
                        Text("List")
                        Image(systemName: "list.bullet")
                    }
                    .tag(ContentViewModel.Tab.snippets)
                    .twsEnable(using: twsViewModel.manager)

                SettingsView()
                    .tabItem {
                        Text("Settings")
                        Image(systemName: "gear")
                    }
                    .tag(ContentViewModel.Tab.settings)
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
        .sheet(item: $twsViewModel.universalLinkLoadedProject) {
            ProjectView(viewModel: $0.viewModel, selectedID: $0.selectedID)
                .twsEnable(using: twsViewModel.manager)
        }
        .fullScreenCover(isPresented: $twsViewModel.presentPopups, content: {
            TWSPopupView(isPresented: $twsViewModel.presentPopups, manager: twsViewModel.manager)
                .twsEnable(using: twsViewModel.manager)
        })
    }
}
