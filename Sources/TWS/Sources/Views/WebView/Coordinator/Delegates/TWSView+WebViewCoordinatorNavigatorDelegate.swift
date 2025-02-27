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

    func navigateBack() {
        assert(webView != nil)
        guard let previousURL = popState() else { return }
        webView?.load(URLRequest(url: previousURL))
    }

    func navigateForward() {
        assert(webView != nil)
        guard !backForwardStack.forwardstack.isEmpty else { return }
    
        backForwardStack.backstack.append(backForwardStack.currentURL)
        backForwardStack.currentURL = backForwardStack.forwardstack.popLast()!
        
        webView?.load(URLRequest(url: backForwardStack.currentURL))
    }

    func reload() {
        assert(webView != nil)
        webView?.reload()
    }
    
    func navigateTo(url: URL) {
        assert(webView != nil)
        pushState(url: backForwardStack.currentURL)
        backForwardStack.currentURL = url
        webView?.load(URLRequest(url: url))
    }
    
    func currentURL() -> URL? {
        assert(webView != nil)
        return backForwardStack.currentURL
    }
    
    func pushState(url: URL) {
        backForwardStack.backstack.append(backForwardStack.currentURL)
        backForwardStack.currentURL = url
        backForwardStack.forwardstack.removeAll()
    }
    
    private func popState() -> URL? {
        guard let last = backForwardStack.backstack.popLast() else { return nil }
        backForwardStack.forwardstack.append(backForwardStack.currentURL)
        backForwardStack.currentURL = last
        return last
    }
}
