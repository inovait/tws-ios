//
//  SnippetsView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit
import SwiftUI
import TWSKit
import TWSModels

struct SnippetsView: View {

    @State var snippets = [TWSSnippet]()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(snippets, id: \.target) { snippet in
                        VStack(alignment: .leading) {
                            Text("\(snippet.id.uuidString.suffix(4)) @ \(snippet.target.path)")
                            TWSView(snippet: snippet)
                                .border(Color.black)
                        }

                    }
                }
                .padding()
            }
            .task {
                let manager = TWSFactory.new()
                manager.run()

                for await snippets in manager.stream {
                    self.snippets = snippets
                }
            }
            .navigationTitle("Snippets")
        }
    }
}
