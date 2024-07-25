//
//  TWSView+NavigationDelegate.swift
//  TWSKit
//
//  Created by Miha Hozjan on 5. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import WebKit
@_implementationOnly import TWSUniversalLinks
@_implementationOnly import TWSCommon

extension WebView.Coordinator: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        logger.debug("[Navigation \(webView.hash)] Navigation finished: \(String(describing: navigation))")
        precondition(Thread.isMainThread, "Not allowed to use on non main thread.")

        _updateHeight(webView: webView)

        // Mandatory to hop the thread, because of UI layout change
        webView.evaluateJavaScript("document.title") { (result, error) in
            if let title = result as? String, error == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.pageTitle = title
                }
            }
        }
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: any Error
    ) {
        var msg = "[Navigation \(webView.hash)] Navigation failed: \(String(describing: navigation)),"
        msg +=  " error: \(error.localizedDescription)"

        logger.debug(msg)
        parent.updateState(for: webView, loadingState: .failed(error))
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        var msg = "[Navigation \(webView.hash)] Provisional navigation failed: \(String(describing: navigation)),"
        msg += "error: \(error.localizedDescription)"

        logger.debug(msg)
        parent.updateState(for: webView, loadingState: .failed(error))
    }

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        logger.debug("[Navigation \(webView.hash)] Navigation started: \(String(describing: navigation))")
    }

    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!
    ) {
        logger.debug("[Navigation \(webView.hash)] Received server redirect: \(String(describing: navigation))")
    }

    func webView(
        _ webView: WKWebView,
        didCommit navigation: WKNavigation!
    ) {
        var msg = "[Navigation \(webView.hash)] Content started arriving for main frame: "
        msg += "\(String(describing: navigation))"

        logger.debug(msg)
        _updateHeight(webView: webView)
    }

    func webViewWebContentProcessDidTerminate(
        _ webView: WKWebView
    ) {
        logger.debug("[Navigation \(webView.hash)] Web content process terminated")
        webView.reload()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        logger.debug("[Navigation \(webView.hash)] Decide policy for navigation action: \(navigationAction)")

        // OAuth request to Google in embedded browsers are not allowed
        if let url = navigationAction.request.url, url.isTWSAuthenticationRequest() {
            logger.info("Google OAuth request detected.")
            redirectedToSafari = true
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
            return
        }

        // Handle deep links that are opened internally
        if let url = navigationAction.request.url,
           (try? TWSUniversalLinkRouter.route(for: url)) != nil {
            logger.info("Internal deep link detected: \(url)")
            parent.onUniversalLinkDetected(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        logger.debug("[Navigation \(webView.hash)] Decide policy for navigation response: \(navigationResponse)")
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        logger.debug("[Navigation \(webView.hash)] Received authentication challenge")
        completionHandler(.performDefaultHandling, nil)  // Default handling for authentication challenge
    }

    // MARK: - Helpers

    private func _updateHeight(
        webView: WKWebView
    ) {
        let cachedScrollHeight: CGFloat?

        if let url = webView.url {
            let hash = WebPageDescription(url)
            cachedScrollHeight = snippetHeightProvider.getHeight(
                for: hash,
                displayID: parent.displayID
            )
        } else {
            cachedScrollHeight = nil
        }

        parent.updateState(
            for: webView,
            loadingState: .loaded,
            dynamicHeight: max(cachedScrollHeight ?? webView.scrollView.contentSize.height, 16)
        )
    }
}
