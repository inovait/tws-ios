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
    }

    public var body: some View {
        WebView(
            identifier: snippet.id,
            url: snippet.target,
            dynamicHeight: $height
        )
        .frame(idealHeight: height)
        .onChange(of: height) { _, height in
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
        webView.configuration.websiteDataStore = .init(forIdentifier: identifier)
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: self.url))
    }

}

extension WebView {

    class Coordinator: NSObject, WKNavigationDelegate {

        var parent: WebView
        private var heightWorkItem: DispatchWorkItem?

        init(_ parent: WebView) {
            self.parent = parent
        }

        public func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            Task { [weak self] in try? await self?._updateHeight(webView) }
        }

        // MARK: - Helpers

        @MainActor
        @discardableResult
        private func _updateHeight(_ webView: WKWebView) async throws -> Bool {
            let scriptBody = #"""
            document.readyState === 'complete' ? (() => {
                const bodyHeight = document.body.scrollHeight;
                const header = document.querySelector('header');
                const headerHeight = header ? header.scrollHeight : 0;
                const footer = document.querySelector('footer');
                const footerHeight = footer ? footer.scrollHeight : 0;
                return bodyHeight + headerHeight + footerHeight;
            })() : -1;
            """#

            let result = try await webView.evaluateJavaScript(scriptBody)
            guard let height = result as? CGFloat else { return false }

            if height <= 0 {
                _scheduleHeightUpdate(webView)
                return false
            } else {
                parent.dynamicHeight = max(height, parent.dynamicHeight)
                return true
            }
        }

        private func _scheduleHeightUpdate(_ webView: WKWebView) {
            heightWorkItem?.cancel()
            heightWorkItem = .init { [weak self] in
                Task { [webView, weak self] in
                    do {
                        try await self?._updateHeight(webView)
                    } catch {
                        assertionFailure("\(error)")
                    }
                }
            }

            guard let heightWorkItem else { fatalError("Can not be nil") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: heightWorkItem)
        }
    }
}
