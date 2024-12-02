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
