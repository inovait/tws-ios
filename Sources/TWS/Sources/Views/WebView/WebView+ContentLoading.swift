////
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

import SwiftUI
import WebKit
@_spi(Internals) import TWSModels
internal import ComposableArchitecture
internal import TWSSnippet

extension WebView {
    func reloadWithProcessedResources(
        webView: WKWebView,
        coordinator: Coordinator,
        isPullToRefresh: Bool = false
    ) {
        let initialUrl = initialUrl()
        if !isPullToRefresh {
            updateState(for: webView, loadingState: .loading(progress: 0))
        }
        
        if initialUrl == state.currentUrl || htmlContent == nil {
            // Reload on initial page
            guard let snippetStore else {
                coordinator.pullToRefresh.setNavigationRequest(navigation: loadProcessedContent(webView: webView))
                return
            }
            
            resourceDownloadHandler.loadNewStore(
                snippetStore,
                onSuccess: { content in
                    guard let content, let responseUrl = content.responseUrl else { return }
                    let urlRequest = URLRequest(url: responseUrl)
                    let htmlToLoad = _handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippetStore.snippet)
                    let navigation = webView.loadSimulatedRequest(urlRequest, responseHTML: htmlToLoad)
                    let navigationDetails = NavigationDetails(WKNavigation: navigation, request: urlRequest)
                    coordinator.pullToRefresh.setNavigationRequest(navigation: navigationDetails)
                },
                onError: { err in
                    updateState(for: webView, loadingState: .failed(err))
                    return
                }
            )
            
            return
        }
        
        if initialUrl == state.lastLoadedUrl, state.currentUrl != state.lastLoadedUrl {
            guard let currentUrl = state.currentUrl else {
                // if current url does not exist load initial
                coordinator.pullToRefresh.setNavigationRequest(navigation: loadProcessedContent(webView: webView))
                return
            }
            // Download SPA page and inject resources on reload
            
            let snippetToReload = TWSSnippet(id: "reloadSnippet", target: currentUrl, dynamicResources: snippet.dynamicResources, visibility: snippet.visibility, engine: snippet.engine, headers: snippet.headers)
            
            let store: StoreOf<TWSSnippetFeature> = .init(
                initialState: TWSSnippetFeature.State(snippet: snippetToReload),
                reducer: { TWSSnippetFeature() })

            store.send(.business(.setLocalDynamicResources(snippetStore?.localDynamicResources ?? [])))
            
            
            resourceDownloadHandler.loadNewStore(
                store,
                onSuccess: { content in
                    guard let content, let responseUrl = content.responseUrl else { return }
                    
                    logger.debug("Load from raw HTML: \(responseUrl)")
                    let htmlToLoad = _handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippetToReload)
                    let urlRequest = URLRequest(url: responseUrl)
                    let navigation = webView.loadSimulatedRequest(urlRequest, responseHTML: htmlToLoad)
                    let navigationDetails = NavigationDetails(WKNavigation: navigation, request: urlRequest)
                    coordinator.pullToRefresh.setNavigationRequest(navigation: navigationDetails)
                },
                onError: { err in
                    updateState(for: webView, loadingState: .failed(err))
                    return
                }
            )
            return
        }
        
        if initialUrl != state.lastLoadedUrl {
            // Normal MPA reload
            if let currentUrl = state.currentUrl, currentUrl != htmlContent?.responseUrl {
                let urlRequest = URLRequest(url: currentUrl)
                let navigation = webView.load(URLRequest(url: currentUrl))
                let navigationDetails = NavigationDetails(WKNavigation: navigation, request: urlRequest)
                coordinator.pullToRefresh.setNavigationRequest(navigation: navigationDetails)
                return
            }
        }
    }
    
    func loadWithConditionallyProcessedResources(
        webView: WKWebView,
        loadUrl: URLRequest,
        coordinator: Coordinator,
        behaveAsSpa: Bool
    ) {
        guard let url = loadUrl.url else { return }
        let initialUrl = initialUrl()
        updateState(for: webView, loadingState: .loading(progress: 0))
        
        // When navigating to initial url
        if url == initialUrl {
            guard let snippetStore else {
                loadProcessedContent(webView: webView)
                return
            }
            
            resourceDownloadHandler.loadNewStore(
                snippetStore,
                onSuccess: { content in
                    let requestUrl = (initialUrl ?? content?.responseUrl) ?? targetURL
                    if let content {
                        let htmlToLoad = _handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippetStore.snippet)
                        webView.loadSimulatedRequest(URLRequest(url: requestUrl), responseHTML: htmlToLoad)
                    }
                },
                onError: { err in
                    updateState(for: webView, loadingState: .failed(err))
                    return
                }
            )
            
            return
        }
        
        if behaveAsSpa {
            let snippetToReload = TWSSnippet(id: "reloadSnippet", target: url, dynamicResources: snippet.dynamicResources, visibility: snippet.visibility, engine: snippet.engine, headers: snippet.headers)
            
            let store: StoreOf<TWSSnippetFeature> = .init(
                initialState: TWSSnippetFeature.State(snippet: snippetToReload),
                reducer: { TWSSnippetFeature() })

            store.send(.business(.setLocalDynamicResources(snippetStore?.localDynamicResources ?? [])))
            
            
            resourceDownloadHandler.loadNewStore(
                store,
                onSuccess: { content in
                    if let content {
                        logger.debug("Load from raw HTML: \(url.absoluteString)")
                        let htmlToLoad = _handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippetToReload)
                        let urlRequest = URLRequest(url: content.responseUrl ?? url)
                        let navigation = webView.loadSimulatedRequest(urlRequest, responseHTML: htmlToLoad)
                        let navigationDetails = NavigationDetails(WKNavigation: navigation, request: urlRequest)
                        coordinator.pullToRefresh.setNavigationRequest(navigation: navigationDetails)
                    }
                },
                onError: { err in
                    updateState(for: webView, loadingState: .failed(err))
                    return
                }
            )
            return
        } else {
            webView.load(loadUrl)
        }
    }
    
    func loadProcessedContent(webView: WKWebView) -> NavigationDetails? {
        // If error is present before the initial load resources were not fetched succesfully
        if let err = snippetStore?.error {
            updateState(for: webView, loadingState: .failed(err))
            return nil
        } else {
            updateState(for: webView, loadingState: .loading(progress: 0.0))
        }
        
        if let content = htmlContent {
            logger.debug("Load from raw HTML: \(targetURL.absoluteString)")
            let htmlToLoad = _handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippet)
            let urlRequest = URLRequest(url: content.responseUrl ?? self.targetURL)
            let navigation = webView.loadSimulatedRequest(urlRequest, responseHTML: htmlToLoad)
            
            return NavigationDetails(WKNavigation: navigation, request: urlRequest)
        }
        
        return nil
    }
    
    func shouldChangeLastLoaded() -> Bool {
        return state.lastLoadedUrl == nil || state.lastLoadedUrl != initialUrl()
    }
    
    private func initialUrl() -> URL? {
        return htmlContent?.responseUrl
    }
}
