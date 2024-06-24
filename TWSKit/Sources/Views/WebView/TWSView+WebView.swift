//
//  TWSView+Coordinator.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    @Binding var dynamicHeight: CGFloat
    let url: URL
    let displayID: String
    let backCommandId: UUID
    let forwardCommandID: UUID
    let snippetHeightProvider: SnippetHeightProvider
    let onHeightCalculated: (CGFloat) -> Void

    init(
        url: URL,
        displayID: String,
        dynamicHeight: Binding<CGFloat>,
        backCommandId: UUID,
        forwardCommandID: UUID,
        snippetHeightProvider: SnippetHeightProvider,
        onHeightCalculated: @escaping @Sendable (CGFloat) -> Void
    ) {
        self.url = url
        self.displayID = displayID
        self._dynamicHeight = dynamicHeight
        self.backCommandId = backCommandId
        self.forwardCommandID = forwardCommandID
        self.snippetHeightProvider = snippetHeightProvider
        self.onHeightCalculated = onHeightCalculated
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: self.url))

        context.coordinator.observe(heightOf: webView)

        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, snippetHeightProvider: snippetHeightProvider)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        defer {
            context.coordinator.backCommandId = backCommandId
            context.coordinator.forwardCommandID = forwardCommandID
        }

        if
            let prevBackCommand = context.coordinator.backCommandId,
            prevBackCommand != backCommandId {
            uiView.goBack()
        }

        if
            let prevForwardCommandID = context.coordinator.forwardCommandID,
            prevForwardCommandID != forwardCommandID {
            uiView.goForward()
        }
    }
}
