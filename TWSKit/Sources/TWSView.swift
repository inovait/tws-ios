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

    @State var height: CGFloat = .zero
    let snippet: TWSSnippet

    public init(snippet: TWSSnippet) {
        self.snippet = snippet
    }

    public var body: some View {
        WebView(
            url: snippet.target,
            dynamicHeight: $height
        )
        .frame(height: height)
    }
}

struct WebView: UIViewRepresentable {

    @Binding var dynamicHeight: CGFloat
    let url: URL

    init(url: URL, dynamicHeight: Binding<CGFloat>) {
        self.url = url
        self._dynamicHeight = dynamicHeight
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

extension WebView {

    class Coordinator: NSObject, WKNavigationDelegate {

        var parent: WebView
        private var heightWorkItem: DispatchWorkItem?

        init(_ parent: WebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            _scheduleHeightUpdate(webView)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            _scheduleHeightUpdate(webView)
        }

        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
            _scheduleHeightUpdate(webView)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            _scheduleHeightUpdate(webView)
        }

        // MARK: - Helpers

        private func _scheduleHeightUpdate(_ webView: WKWebView) {
            heightWorkItem?.cancel()
            heightWorkItem = .init { [weak self] in
                self?._updateHeight(webView)
            }

            guard let heightWorkItem else { fatalError("Can not be nil") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: heightWorkItem)
        }

        private func _updateHeight(_ webView: WKWebView) {
            let script = "document.readyState === 'complete' ? document.body.scrollHeight : -1"
            webView.evaluateJavaScript(script, completionHandler: { (height, _) in
                DispatchQueue.main.async { [weak self] in
                    guard let height = height as? CGFloat else { return }

                    if height <= 0 {
                        self?._scheduleHeightUpdate(webView)
                    } else {
                        self?.parent.dynamicHeight = height
                    }
                }
            })
        }
    }
}
