//
//  TWSView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSModels

public struct TWSView: View {

    let snippet: TWSSnippet
    let handler: TWSManager
    let displayID: String

    public init(
        snippet: TWSSnippet,
        using handler: TWSManager,
        displayID id: String
    ) {
        self.snippet = snippet
        self.handler = handler
        self.displayID = id
    }

    public var body: some View {
        _TWSView(
            snippet: snippet,
            using: handler,
            displayID: displayID
        )
        .id(handler.store.snippets.snippets[id: snippet.id]?.updateCount ?? 0)
        .id(snippet.id)
    }
}

private struct _TWSView: View {

    @State var height: CGFloat = 16
    @State private var backCommandID = UUID()
    @State private var forwardCommandID = UUID()
    let snippet: TWSSnippet
    let handler: TWSManager
    let displayID: String

    init(
        snippet: TWSSnippet,
        using handler: TWSManager,
        displayID id: String
    ) {
        self.snippet = snippet
        self.handler = handler
        self.displayID = id.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    backCommandID = .init()
                } label: {
                    Image(systemName: "arrowshape.backward.fill")
                }

                Button {
                    forwardCommandID = .init()
                } label: {
                    Image(systemName: "arrowshape.forward.fill")
                }
            }

            Divider()

            WebView(
                url: snippet.target,
                displayID: displayID,
                dynamicHeight: $height,
                backCommandId: backCommandID,
                forwardCommandID: forwardCommandID,
                snippetHeightProvider: handler.snippetHeightProvider
            ) { height in
                handler.set(height: height, for: snippet, displayID: displayID)
            }
            .frame(idealHeight: height)
        }
        .task {
            if let height = handler.store.snippets.snippets[id: snippet.id]?.displayInfo.displays[displayID]?.height {
                self.height = height
            }
        }
    }
}
