//
//  CustomInjectionExample.swift
//  TheWebSnippet
//
//  Created by Miha Hozjan on 2. 12. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWS

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
