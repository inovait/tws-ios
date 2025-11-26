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
        guard let urlToReload = state.currentUrl else { return }
        let initialUrl = initialUrl()
        
        setNavigationEvent(TWSNavigationEvent(sourceURL: state.currentUrl, type: isPullToRefresh ? .pullToRefresh : .reload))
        
        if !isPullToRefresh {
            updateState(for: webView, loadingState: .loading(progress: 0))
        }
        
        if initialUrl == state.currentUrl || htmlContent == nil {
            // Reload on initial page
            guard let snippetStore else {
                setNavigationRequest(loadProcessedContent(webView: webView), coordinator: coordinator, isPullToRefresh: isPullToRefresh)
                return
            }
            
            resourceDownloadHandler.loadNewStore(
                snippetStore,
                onSuccess: { content in
                    guard let content, let responseUrl = content.responseUrl else {
                        return
                    }
                    let navigation = createAndLoadURLRequest(for: responseUrl, using: snippetStore.snippet, with: content, in: webView)
                    setNavigationRequest(navigation, coordinator: coordinator, isPullToRefresh: isPullToRefresh)
                },
                shouldCancel: { shouldCancelNavigation(webView: webView, coordinator: coordinator) },
                onError: { err in
                    handleError(for: webView, using: coordinator, error: err)
                }
            )
            
            return
        }
        
        if initialUrl == state.lastLoadedUrl, state.currentUrl != state.lastLoadedUrl {
            guard let currentUrl = state.currentUrl else {
                // if current url does not exist load initial
                setNavigationRequest(loadProcessedContent(webView: webView), coordinator: coordinator, isPullToRefresh: isPullToRefresh)
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
                    guard let content, let responseUrl = content.responseUrl, let currentUrl = state.currentUrl else {
                        return
                    }
                    
                    let navigation = createAndLoadURLRequest(for: responseUrl, using: snippetToReload, with: content, in: webView)
                    setNavigationRequest(navigation, coordinator: coordinator, isPullToRefresh: isPullToRefresh)
                },
                shouldCancel: { shouldCancelNavigation(webView: webView, coordinator: coordinator) },
                onError: { err in
                    handleError(for: webView, using: coordinator, error: err)
                    return
                }
            )
            return
        }
        
        if initialUrl != state.lastLoadedUrl {
            // Normal MPA reload
            if let currentUrl = state.currentUrl, currentUrl != htmlContent?.cachedResponse?.responseUrl {
                let urlRequest = URLRequest(url: currentUrl)
                let navigation = webView.load(urlRequest)
                setNavigationRequest(navigation, coordinator: coordinator, isPullToRefresh: isPullToRefresh)
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
            setNavigationEvent(TWSNavigationEvent(sourceURL: state.currentUrl, type: .load))
            guard let snippetStore else {
                setNavigationRequest(loadProcessedContent(webView: webView), coordinator: coordinator)
                return
            }
            
            resourceDownloadHandler.loadNewStore(
                snippetStore,
                onSuccess: { content in
                    let responseUrl = (initialUrl ?? content?.responseUrl) ?? targetURL
                    if let content {
                        let navigation = createAndLoadURLRequest(for: responseUrl, using: snippetStore.snippet, with: content, in: webView)
                        setNavigationRequest(navigation, coordinator: coordinator)
                    }
                },
                shouldCancel: { shouldCancelNavigation(webView: webView, coordinator: coordinator) },
                onError: { err in
                    handleError(for: webView, using: coordinator, error: err)
                }
            )
            
            return
        }
        
        if behaveAsSpa {
            setNavigationEvent(TWSNavigationEvent(sourceURL: state.currentUrl, type: .spa))
            let snippetToReload = TWSSnippet(id: "reloadSnippet", target: url, dynamicResources: snippet.dynamicResources, visibility: snippet.visibility, engine: snippet.engine, headers: snippet.headers)
            
            let store: StoreOf<TWSSnippetFeature> = .init(
                initialState: TWSSnippetFeature.State(snippet: snippetToReload),
                reducer: { TWSSnippetFeature() })

            store.send(.business(.setLocalDynamicResources(snippetStore?.localDynamicResources ?? [])))
            
            resourceDownloadHandler.loadNewStore(
                store,
                onSuccess: { content in
                    if let content, let responseUrl = content.responseUrl {
                        let navigation = createAndLoadURLRequest(for: responseUrl, using: snippetToReload, with: content, in: webView)
                        setNavigationRequest(navigation, coordinator: coordinator)
                    }
                },
                shouldCancel: { shouldCancelNavigation(webView: webView, coordinator: coordinator) },
                onError: { err in
                    handleError(for: webView, using: coordinator, error: err)
                }
            )
            return
        } else {
            setNavigationEvent(TWSNavigationEvent(sourceURL: state.currentUrl, type: .nativeLoad))
            let navigation = webView.load(loadUrl)
            
            setNavigationRequest(navigation, coordinator: coordinator)
        }
    }
    
    func loadProcessedContent(webView: WKWebView) -> WKNavigation? {
        // If error is present before the initial load resources were not fetched succesfully
        if case let .failed(err) = htmlContent {
            updateState(for: webView, loadingState: .failed(err))
            return nil
        } else {
            updateState(for: webView, loadingState: .loading(progress: 0.0))
        }
        
        if let content = htmlContent?.cachedResponse {
            let responseUrl = content.responseUrl ?? self.targetURL
            setNavigationEvent(TWSNavigationEvent(sourceURL: state.currentUrl, type: .load))

            let navigation = createAndLoadURLRequest(for: responseUrl, using: snippet, with: content, in: webView)
            setNavigationRequest(navigation)
            
            return navigation
        }
        
        return nil
    }
    
    func shouldChangeLastLoaded() -> Bool {
        return state.lastLoadedUrl == nil || state.lastLoadedUrl != initialUrl()
    }
    
    func cancelNavigation(coordinator: Coordinator) {
        resourceDownloadHandler.cancelDownload()
        resourceDownloadHandler.destroyStore()
        coordinator.pullToRefresh.cancelRefresh()
        navigationEventHandler.cancelNavigationEvent()
    }
    
    func shouldCancelNavigation(webView: WKWebView, coordinator: Coordinator) -> Bool {
        if navigationEventHandler.navigationEvent.isIdle() {
            return false
        }
        
        if state.currentUrl == navigationEventHandler.navigationEvent.getSourceURL() || navigationEventHandler.navigationEvent.isNativeLoad() {
            return false
        }
        
        cancelNavigation(coordinator: coordinator)
        updateState(for: webView, loadingState: .loaded)
        return true
    }
    
    private func initialUrl() -> URL? {
        return htmlContent?.cachedResponse?.responseUrl
    }
    
    private func handleError(for webview: WKWebView, using coordinator: Coordinator, error: Error) {
        cancelNavigation(coordinator: coordinator)
        updateState(for: webview, loadingState: .failed(error))
    }
    
    private func createAndLoadURLRequest(for url: URL, using snippet: TWSSnippet, with content: ResourceResponse, in webView: WKWebView) -> WKNavigation {
        logger.debug("Load from raw HTML: \(content.responseUrl?.absoluteString)")
        let htmlToLoad = _handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippet)
        let urlRequest = URLRequest(url: url)
        return webView.loadSimulatedRequest(urlRequest, responseHTML: htmlToLoad)
    }
    
    private func setNavigationEvent(_ event: TWSNavigationEvent) {
        DispatchQueue.main.async {
            navigationEventHandler.setNavigationEvent(navigationEvent: event)
        }
    }
    
    private func setNavigationRequest(_ navigation: WKNavigation) {
        DispatchQueue.main.async {
            navigationEventHandler.getNavigationEvent().setNavigation(navigation)
        }
    }
    
    private func setNavigationRequest(_ navigation: WKNavigation?, coordinator: Coordinator, isPullToRefresh: Bool = false) {
        DispatchQueue.main.async {
            navigationEventHandler.getNavigationEvent().setNavigation(navigation)
            if isPullToRefresh {
                coordinator.pullToRefresh.setNavigationRequest(navigation: navigation)
            }
        }
    }
}
