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
import WebKit

extension WebView.Coordinator: TWSViewNavigatorDelegate {
    func load(url: URLRequest, behaveAsSpa: Bool = false) {
        assert(webView != nil)
        if let webView {
            parent.loadWithConditionallyProcessedResources(webView: webView, loadUrl: url, coordinator: self, behaveAsSpa: behaveAsSpa)
        }
    }
    
    func navigateBack() {
        assert(webView != nil)
        webView?.goBack()
    }

    func navigateForward() {
        assert(webView != nil)
        webView?.goForward()
    }

    func reload() {
        assert(webView != nil)
        guard let webView else { return }
        parent.reloadWithProcessedResources(webView: webView, coordinator: self)
    }
    
    func pushState(path: String) {
        webView?.navigateFromNativeOrFallback(path: path, isReplaceState: false)
    }
    
    func replaceState(path: String) {
        webView?.navigateFromNativeOrFallback(path: path, isReplaceState: true)
    }
    
    func evaluateJavaScript(script: String, completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)? = nil) {
        assert(webView != nil)
        webView?.evaluateJavaScript(script, completionHandler: completionHandler)
    }
}

extension WKWebView {
    func navigateFromNativeOrFallback(path: String, isReplaceState: Bool) {
        let navigationExists = "typeof window.navigateFromNative === 'function';"
        self.evaluateJavaScript(navigationExists) { result, err in
            guard let result = result as? Bool else {
                return
            }
            
            if result {
                logger.info("Navigating with navigateFromNative")
                let navigate =
                """
                    navigateFromNative('\(path)', { replace: \(isReplaceState) });
                    console.log('navigateFromNative called');
                """
                self.evaluateJavaScript(navigate)
            } else {
                let navigate = isReplaceState ? "replaceState" : "pushState"
                logger.info("Navigating with \(navigate)")
                
                let fallbackNavigate =
                """
                    history.\(navigate)(null, '', '\(path)');
                    window.dispatchEvent(new Event('popstate'));
                    console.log('fallback navigation');
                """
                
                self.evaluateJavaScript(fallbackNavigate)
            }
            
        }
    }
}
