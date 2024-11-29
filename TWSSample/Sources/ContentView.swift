//
//  ContentView.swift
//  Sample
//
//  Created by Miha Hozjan on 27. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWS

struct ContentView: View {

    @Environment(TWSManager.self) var tws
    @State private var interceptor = CustomInterceptor()

    var body: some View {
        ZStack {
            if let snippet = tws.snippets().first(where: { $0.id == "customInterceptors" }) {
                TWSView(snippet: snippet)
                    .twsBind(interceptor: interceptor)
                    .sheet(item: $interceptor.destination) { destination in
                        switch destination {
                        case .customTabsExample:
                            CustomTabsExample()
                                .twsBind(interceptor: DefaultInterceptor())

                        case .mustacheExample:
                            CustomMustacheExample()
                                .twsBind(interceptor: DefaultInterceptor())

                        case .injectionExample:
                            CustomInjectionExample()
                                .twsBind(interceptor: DefaultInterceptor())

                        case .permissionsExample:
                            CustomPermissionExample()
                                .twsBind(interceptor: DefaultInterceptor())
                        }
                    }
            }
        }
    }
}

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

struct CustomMustacheExample: View {

    @Environment(TWSManager.self) var tws
    @State private var tab = "aboutMustache"

    var body: some View {
        TabView(selection: $tab) {
            ForEach(
                tws.snippets()
                    .filter { Set(["aboutMustache", "howToMustache"]).contains($0.id) }
            ) { snippet in
                TWSView(snippet: snippet)
                    .tag(snippet.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

struct CustomInjectionExample: View {

    @Environment(TWSManager.self) var tws
    @State private var alert: String?
    @State private var tab = "rawHtml"

    var body: some View {
        TabView(selection: $tab) {
            ForEach(
                tws.snippets()
                    .filter { Set(["rawHtml", "injectingCSS", "injectingJavascript", "resultingPage"]).contains($0.id) }
            ) { snippet in
                TWSView(snippet: snippet)
                    .tag(snippet.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))

    }
}

struct CustomPermissionExample: View {

    @Environment(TWSManager.self) var tws
    @State private var alertMsg = ""
    @State private var showAlert = false

    var body: some View {
        if let snippet = tws.snippets().first(where: { $0.id == "permissions" }) {
            TWSView(snippet: snippet)
                .twsOnDownloadCompleted { state in
                    switch state {
                    case let .completed(info):
                        var log = "Download completed successfully. File name:"
                        log += " \(info.downloadedFilename)"
                        log += ", location: \(info.downloadedLocation)"
                        alertMsg = log
                        showAlert = true

                    case let .failed(error):
                        alertMsg = error.localizedDescription
                        showAlert = true

                    @unknown default:
                        break
                    }
                }
                .alert(alertMsg, isPresented: $showAlert, actions: {})
        }
    }
}

@MainActor
@Observable
class CustomInterceptor: TWSViewInterceptor {

    var destination: Destination?

    func handleUrl(
        _ url: URL
    ) -> Bool {
        if let destination = Destination(rawValue: url.lastPathComponent) {
            self.destination = destination
            return true
        }

        return false
    }
}

extension CustomInterceptor {

    enum Destination: String, Identifiable {
        var id: String { rawValue }

        case customTabsExample
        case mustacheExample
        case injectionExample
        case permissionsExample
    }
}

@MainActor
@Observable
class DefaultInterceptor: TWSViewInterceptor {

    func handleUrl(
        _ url: URL
    ) -> Bool {
        return false
    }
}
