//
//  TWSView+UIDelegate.swift
//  TWSKit
//
//  Created by Miha Hozjan on 5. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import WebKit

extension WebView.Coordinator: WKUIDelegate {

    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        var msg = "[UI \(webView.hash)] Create web view with configuration: \(configuration)"
        msg += ", for navigation action: \(navigationAction)"
        msg += ", window features: \(windowFeatures)"

        logger.debug(msg)

        let newWebView = WKWebView(frame: webView.frame, configuration: configuration)
        newWebView.allowsBackForwardNavigationGestures = true
        newWebView.scrollView.bounces = false
        newWebView.scrollView.isScrollEnabled = true
        newWebView.navigationDelegate = self
        newWebView.uiDelegate = self
        newWebView.load(navigationAction.request)

        do {
            try navigationProvider.present(
                webView: newWebView,
                on: webView,
                animated: true,
                completion: nil
            )

            return newWebView
        } catch {
            logger.err("[UI \(webView.hash)] Failed to create a new web view: \(error)")
            return nil
        }
    }

    public func webViewDidClose(_ webView: WKWebView) {
        logger.debug("[UI \(webView.hash)] Web view did close")
        do {
            try navigationProvider.didClose(
                webView: webView,
                animated: true,
                completion: nil
            )
        } catch {
            logger.err("[UI \(webView.hash)] Failed to close the web view: \(webView)")
        }
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        var msg = "[UI \(webView.hash)] Run JavaScript alert panel with message: \(message), "
        msg += "initiated by frame: \(frame)"

        logger.debug(msg)
        completionHandler()
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        var msg = "[UI \(webView.hash)] Run JavaScript confirm panel with message: \(message), "
        msg += "initiated by frame: \(frame)"

        logger.debug(msg)
        completionHandler(true)
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        var msg = "[UI \(webView.hash)] Run JavaScript text input panel with prompt: \(prompt)"
        msg += ", default text: \(String(describing: defaultText)), initiated by frame: \(frame)"
        logger.debug(msg)
        completionHandler(defaultText)
    }
}
