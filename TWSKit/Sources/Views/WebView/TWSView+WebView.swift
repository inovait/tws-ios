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
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool

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
        onHeightCalculated: @escaping @Sendable (CGFloat) -> Void,
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>
    ) {
        self.url = url
        self.displayID = displayID
        self._dynamicHeight = dynamicHeight
        self.backCommandId = backCommandId
        self.forwardCommandID = forwardCommandID
        self.snippetHeightProvider = snippetHeightProvider
        self.onHeightCalculated = onHeightCalculated
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: self.url))

        context.coordinator.observe(heightOf: webView)
        _updateState(for: webView)

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

        _updateState(for: uiView)
    }

    // MARK: - Helpers

    private func _updateState(for webView: WKWebView) {
        // Thread hop is mandatory
        DispatchQueue.main.async {
            // TODO: remove print; only when it changes
            print(
            """
            Update state:
            can go back: \(webView.canGoBack)
            can go forward: \(webView.canGoForward)
            ----------------------------
            """
            )

            canGoBack = webView.canGoBack
            canGoForward = webView.canGoForward
        }
    }
}
