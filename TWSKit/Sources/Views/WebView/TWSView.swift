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
    let canGoBack: Binding<Bool>
    let canGoForward: Binding<Bool>

    public init(
        snippet: TWSSnippet,
        using handler: TWSManager,
        displayID id: String,
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>
    ) {
        self.snippet = snippet
        self.handler = handler
        self.displayID = id
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }

    public var body: some View {
        ZStack {
            _TWSView(
                snippet: snippet,
                using: handler,
                displayID: displayID,
                canGoBack: canGoBack,
                canGoForward: canGoForward
            )
        }
        .id(handler.store.snippets.snippets[id: snippet.id]?.updateCount ?? 0)
        .id(snippet.id)
    }
}

private struct _TWSView: View {

    @State var height: CGFloat = 16
    @State private var backCommandID = UUID()
    @State private var forwardCommandID = UUID()
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool

    let snippet: TWSSnippet
    let handler: TWSManager
    let displayID: String

    init(
        snippet: TWSSnippet,
        using handler: TWSManager,
        displayID id: String,
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>
    ) {
        self.snippet = snippet
        self.handler = handler
        self.displayID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
    }

    var body: some View {
        WebView(
            url: snippet.target,
            displayID: displayID,
            dynamicHeight: $height,
            backCommandId: backCommandID,
            forwardCommandID: forwardCommandID,
            snippetHeightProvider: handler.snippetHeightProvider,
            onHeightCalculated: { height in
                handler.set(height: height, for: snippet, displayID: displayID)
            },
            canGoBack: $canGoBack,
            canGoForward: $canGoForward
        )
        .frame(idealHeight: height)
//        .task {
//            if let height = handler.store.snippets.snippets[id: snippet.id]?.displayInfo.displays[displayID]?.height {
//                self.height = height
//            }
//        }
        .onReceive(
            NotificationCenter.default.publisher(for: Notification.Name.Navigation.Back)
        ) { notification in
            guard NotificationBuilder.shouldReact(to: notification, as: snippet, displayID: displayID)
            else { return }
            backCommandID = UUID()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: Notification.Name.Navigation.Forward)
        ) { notification in
            guard NotificationBuilder.shouldReact(to: notification, as: snippet, displayID: displayID)
            else { return }
            forwardCommandID = UUID()
        }
    }
}
