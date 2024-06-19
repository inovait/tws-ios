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
        self._height = .init(initialValue: handler.height(for: snippet, displayID: id) ?? .zero)
        self.displayID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        print(self._height.wrappedValue)
    }

    public var body: some View {
        WebView(
            identifier: snippet.id,
            url: snippet.target,
            dynamicHeight: $height
        )
        .frame(idealHeight: height)
        .onChange(of: height) { _, height in
            print("NewHeight: \(height)")
            guard height > 0 else { return }
            handler.set(height: height, for: snippet, displayID: displayID)
        }
    }
}

struct WebView: UIViewRepresentable {

    @Binding var dynamicHeight: CGFloat
    let identifier: UUID
    let url: URL

    init(
        identifier: UUID,
        url: URL,
        dynamicHeight: Binding<CGFloat>
    ) {
        self.identifier = identifier
        self.url = url
        self._dynamicHeight = dynamicHeight
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
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
