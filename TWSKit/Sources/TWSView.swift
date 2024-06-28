//
//  TWSView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import WebKit
import TWSModels

public struct TWSView: View {

    @State var height: CGFloat
    @State var pageTitle: String
    let snippet: TWSSnippet
    let handler: TWSManager
    let displayID: String
    let onPageTitleChanged: ((String) -> Void)?

    public init(
        snippet: TWSSnippet,
        using handler: TWSManager,
        displayID id: String,
        onPageTitleChanged: ((String) -> Void)? = nil
    ) {
        let height = handler.store.snippets.snippets[id: snippet.id]?.displayInfo.displays[id]?.height

        self.snippet = snippet
        self.handler = handler
        self._height = .init(initialValue: height ?? .zero)
        self._pageTitle = .init(initialValue: "")
        self.displayID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self.onPageTitleChanged = onPageTitleChanged
    }

    public var body: some View {
        WebView(
            url: snippet.target,
            dynamicHeight: $height,
            pageTitle: $pageTitle
        )
        .frame(idealHeight: height)
        .onChange(of: height) { _, height in
            guard height > 0 else { return }
            handler.set(height: height, for: snippet, displayID: displayID)
        }
        .onChange(of: pageTitle) { _, pageTitle in
            onPageTitleChanged?(pageTitle)
        }
        .id(handler.store.snippets.snippets[id: snippet.id]?.updateCount ?? 0)
    }
}

struct WebView: UIViewRepresentable {

    @Binding var dynamicHeight: CGFloat
    @Binding var pageTitle: String
    let url: URL

    init(
        url: URL,
        dynamicHeight: Binding<CGFloat>,
        pageTitle: Binding<String>
    ) {
        self.url = url
        self._dynamicHeight = dynamicHeight
        self._pageTitle = pageTitle
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: self.url))

        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

extension WebView {

    class Coordinator: NSObject {

        var parent: WebView
        var heightWorkItem: DispatchWorkItem?

        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}
