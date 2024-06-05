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

    @Environment(TWSViewModel.self) private var twsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(twsViewModel.snippets, id: \.target) { snippet in
                        VStack(alignment: .leading) {
                            TWSView(
                                snippet: snippet,
                                using: twsViewModel.manager,
                                displayID: "list-\(snippet.id.uuidString)"
                            )
                            .border(Color.black)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Snippets")
        }
        .onAppear {
            print("-> on appear snippets view \(twsViewModel.snippets.count)")
        }
        .onChange(of: twsViewModel.snippets.count) { _, newValue in
            print("-> on change \(newValue)", Date())
        }
    }
}
