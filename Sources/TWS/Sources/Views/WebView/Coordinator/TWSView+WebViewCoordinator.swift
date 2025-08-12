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
import SwiftUI

extension WebView {

    @MainActor
    class Coordinator: NSObject {

        var parent: WebView
        var heightObserver: NSKeyValueObservation?
        var urlObserver: NSKeyValueObservation?
        var loadingProgress: NSKeyValueObservation?
        private var canGoBackObserver: NSKeyValueObservation?
        private var canGoForwardObserver: NSKeyValueObservation?
        var isConnectedToNetwork = true
        var redirectedToSafari = false
        var openURL: URL?
        var downloadInfo = TWSDownloadInfo()
        @Bindable var state: TWSViewState

        let id = UUID().uuidString.suffix(4)
        let snippetHeightProvider: SnippetHeightProvider
        let navigationProvider: NavigationProvider
        let downloadCompleted: ((TWSDownloadState) -> Void)?
        let interceptor: TWSViewInterceptor?
        var pullToRefresh: PullToRefresh!
        weak var webView: WKWebView?

        init(
            _ parent: WebView,
            snippetHeightProvider: SnippetHeightProvider,
            navigationProvider: NavigationProvider,
            downloadCompleted: ((TWSDownloadState) -> Void)?,
            interceptor: TWSViewInterceptor?,
            state: Bindable<TWSViewState>
        ) {
            self.parent = parent
            self.snippetHeightProvider = snippetHeightProvider
            self.navigationProvider = navigationProvider
            self.downloadCompleted = downloadCompleted
            self.pullToRefresh = PullToRefresh()
            self.interceptor = interceptor
            self._state = state
            super.init()
            logger.debug("INIT Coordinator for WKWebView \(parent.id)-\(id)")
        }

        deinit {
            heightObserver?.invalidate()
            heightObserver = nil
            self.webView = nil
            logger.debug("DEINIT Coordinator for WKWebView \(id)")
        }

        // MARK: - Internals

        func observe(heightOf webView: WKWebView) {
            var prevHeight: CGFloat = .zero

            heightObserver = webView.scrollView.observe(
                \.contentSize,
                options: [.new]
            ) { [weak self] _, change in
                MainActor.assumeIsolated { [weak self] in
                    guard
                        let self = self,
                        let newHeight = change.newValue?.height,
                        newHeight != prevHeight
                    else { return }

                    prevHeight = newHeight
                    if let currentPage = webView.url {
                        let hash = WebPageDescription(currentPage)
                        self.snippetHeightProvider.set(
                            height: newHeight,
                            for: hash,
                            displayID: self.parent.displayID
                        )
                    }

                    self.parent.updateState(for: webView, loadingState: nil, dynamicHeight: newHeight)
                }
            }
        }
        
        func observe(currentUrlOf webview: WKWebView) {
            urlObserver = webview.observe(\.url, options: [.new]) { [weak self] _, change in
                MainActor.assumeIsolated { [weak self] in
                    guard
                        let unwrapped = change.newValue,
                        let url = unwrapped
                    else { return }
                    guard let self = self else { return }
                    if self.parent.wkWebView == webview {
                        self.parent.state.currentUrl = url
                        self.parent.updateState(for: webview)
                    }
                }
            }
        }
        
        func observe(canGoBackFor webview: WKWebView) {
            canGoBackObserver = webview.observe(\.canGoBack, options: [.new]) { [weak self] _, change in
                MainActor.assumeIsolated { [weak self] in
                    guard let self = self else { return }
                    if self.isMainWebView(webView: webview) {
                        self.parent.updateState(for: webview)
                    }
                }
            }
        }
        
        func observe(canGoForwardFor webview: WKWebView) {
            canGoForwardObserver = webview.observe(\.canGoForward, options: [.new]) { [weak self] _, change in
                MainActor.assumeIsolated { [weak self] in
                    guard let self = self else { return }
                    if self.isMainWebView(webView: webview) {
                        self.parent.updateState(for: webview)
                    }
                }
            }
        }
        
        func observe(loadingProgressOf webview: WKWebView) {
            loadingProgress = webview.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
                MainActor.assumeIsolated { [weak self] in
                    guard let self = self else { return }
                    guard let newValue = change.newValue else { return }
                    
                    if case .loading(let progress) = self.parent.state.loadingState, newValue > progress {
                        self.parent.updateState(for: webview, loadingState: .loading(progress: newValue))
                    }
                }
                
            }
        }
        
        // MARK: Helpers
        func isMainWebView(webView: WKWebView) -> Bool {
            parent.wkWebView == webView
        }
    }
}
