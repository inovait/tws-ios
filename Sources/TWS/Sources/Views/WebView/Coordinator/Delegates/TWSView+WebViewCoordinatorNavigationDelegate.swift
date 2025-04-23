//
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
@preconcurrency import WebKit
internal import TWSUniversalLinks
internal import TWSCommon

extension WebView.Coordinator: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        logger.debug("[Navigation \(webView.hash)] Navigation finished: \(String(describing: navigation))")
        precondition(Thread.isMainThread, "Not allowed to use on non main thread.")

        _ = pullToRefresh.verifyForRefresh(navigation: navigation)
        _updateHeight(webView: webView)

        // Mandatory to hop the thread, because of UI layout change
        webView.evaluateJavaScript("document.title") { (result, error) in
            if let title = result as? String, error == nil, self.parent.wkWebView == webView {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.state.title = title
                    if let url = webView.url {
                        self?.parent.state.lastLoadedUrl = url
                        self?.parent.state.currentUrl = url
                    }
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
        if parent.wkWebView == webView {
            parent.updateState(for: webView, loadingState: .failed(error))
        } else {
            self.navigationProvider._presentedVC?.presentedWebView?.showError(message: error.localizedDescription)
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        var msg = "[Navigation \(webView.hash)] Provisional navigation failed: \(String(describing: navigation)),"
        msg += "error: \(error.localizedDescription)"

        logger.debug(msg)

        let nsError = error as NSError
        // Error code 102: WebKitErrorFrameLoadInterruptedByPolicyChange (expected during downloads)
        // Important to not show the error screen, because we manually interrupted the loading
        if nsError.code == 102 || nsError.code == NSURLErrorCancelled {
            return
        }
        if parent.wkWebView == webView {
            parent.updateState(for: webView, loadingState: .failed(error))
        } else {
            self.navigationProvider._presentedVC?.presentedWebView?.showError(message: error.localizedDescription)
        }
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
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        logger.debug("[Navigation \(webView.hash)] Decide policy for navigation action: \(navigationAction)")
        if let url = navigationAction.request.url, interceptor?.handleUrl(url) == true {
            decisionHandler(.cancel, preferences)
            return
        }

        // OAuth request to Google in embedded browsers are not allowed
        if let url = navigationAction.request.url, url.isTWSAuthenticationRequest() {
            logger.info("Google OAuth request detected.")
            redirectedToSafari = true
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel, preferences)
            return
        }

        // Handle deep links that are opened internally
        if let url = navigationAction.request.url,
           (try? TWSUniversalLinkRouter.route(for: url)) != nil {
            logger.info("Internal deep link detected: \(url)")
            parent.onUniversalLinkDetected(url)
            decisionHandler(.cancel, preferences)
            return
        }

        if navigationAction.shouldPerformDownload {
            decisionHandler(.download, preferences)
            return
        }

        decisionHandler(.allow, preferences)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void
    ) {
        logger.debug("[Navigation \(webView.hash)] Decide policy for navigation response: \(navigationResponse)")
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @MainActor @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        logger.debug("[Navigation \(webView.hash)] Received authentication challenge")
        completionHandler(.performDefaultHandling, nil)  // Default handling for authentication challenge
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
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
