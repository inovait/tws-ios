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
        
        let webViewWithErrorOverlay = WebViewWithErrorOverlay(webView: newWebView)
        
        do {
            try navigationProvider.present(
                webView: webViewWithErrorOverlay,
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
        completionHandler: @escaping @MainActor @Sendable () -> Void
    ) {
        var msg = "[UI \(webView.hash)] Run JavaScript alert panel with message: \(message), "
        msg += "initiated by frame: \(frame)"
        logger.debug(msg)

        let alertController = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(.init(title: "OK", style: .default, handler: { _ in completionHandler() }))
        if !navigationProvider.present(from: webView, alert: alertController, animated: true, completion: nil) {
            completionHandler()
        }
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            _webView(
                webView,
                runJavaScriptConfirmPanelWithMessage: message,
                initiatedByFrame: frame
            ) { result in
                continuation.resume(returning: result)
            }
        }
    }

    private func _webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        var msg = "[UI \(webView.hash)] Run JavaScript confirm panel with message: \(message), "
        msg += "initiated by frame: \(frame)"
        logger.debug(msg)

        let alertController = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )

        alertController.addAction(.init(title: "OK", style: .default, handler: { _ in completionHandler(true) }))
        alertController.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in completionHandler(false) }))
        if !navigationProvider.present(from: webView, alert: alertController, animated: true, completion: nil) {
            completionHandler(false)
        }
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (String?) -> Void
    ) {
        var msg = "[UI \(webView.hash)] Run JavaScript text input panel with prompt: \(prompt)"
        msg += ", default text: \(String(describing: defaultText)), initiated by frame: \(frame)"
        logger.debug(msg)

        let alertController = UIAlertController(
            title: nil,
            message: prompt,
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completionHandler(nil)
        }))

        if !navigationProvider.present(from: webView, alert: alertController, animated: true, completion: nil) {
            completionHandler(nil)
        }
    }

    func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        do {
            switch type {
            case .camera:
                try await parent.cameraMicrophoneServicesBridge.checkCameraPermission()

            case .microphone:
                try await parent.cameraMicrophoneServicesBridge.checkMicrophonePermission()

            case .cameraAndMicrophone:
                try await parent.cameraMicrophoneServicesBridge.checkCameraPermission()
                try await parent.cameraMicrophoneServicesBridge.checkMicrophonePermission()

            @unknown default:
                break
            }
        } catch {
            return .deny
        }

        return .grant
    }
}
