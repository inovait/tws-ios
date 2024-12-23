//
//  MixAndMatch_00.swift
//  
//
//  Created by Miha Hozjan on 25. 11. 24.
//

import SwiftUI
import TWS

struct HomeView: View {

    @Environment(TWSManager.self) var tws

    var  body: some View {
        TabView {
            ForEach(tws.snippets()) { snippet in
                RemoteSnippetTab(snippet: snippet)
            }
        }
    }
}

struct RemoteSnippetTab: View {

    let snippet: TWSSnippet

    var body: some View {
        TWSView(snippet: snippet)
    }
}
