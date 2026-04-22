//
//  DownloadedContentProvider.swift
//  TWS
//
//  Created by Sven Kotnik on 22. 4. 26.
//

import Foundation
import WebKit
internal import ComposableArchitecture
internal import TWSSnippet
@_spi(Internals) import TWSModels

@MainActor
final class DownloadedContentProvider: WebViewContentProviding {
    private(set) var wv: WebView
    
    private var resourceDownloadHandler: ResourceDownloadHandler = .init()
    
    init(webview: WebView) {
        self.wv = webview
    }

    func load(webView: WKWebView) -> WKNavigation? {
        // If error is present before the initial load resources were not fetched succesfully
        if case let .failed(err) = wv.htmlContent {
            wv.updateState(for: webView, loadingState: .failed(err))
            return nil
        } else {
            wv.updateState(for: webView, loadingState: .loading(progress: 0.0))
        }
        
        if let content = wv.htmlContent?.cachedResponse {
            let responseUrl = content.responseUrl ?? wv.targetURL
            wv.setNavigationEvent(TWSNavigationEvent(sourceURL: wv.state.currentUrl, type: .load))

            let navigation = createAndLoadURLRequest(for: responseUrl, using: wv.snippet, with: content, in: webView)
            wv.setNavigationRequest(navigation)
            
            return navigation
        }
        
        return nil
    }
    
    func load(webView: WKWebView, coordinator: WebView.Coordinator, _ loadUrl: URLRequest, behaveAsSPA: Bool = false) {
        guard let url = loadUrl.url else { return }
        let initialUrl = wv.initialUrl()

        wv.updateState(for: webView, loadingState: .loading(progress: 0))

        // When navigating to initial url
        if url == initialUrl {
            wv.setNavigationEvent(TWSNavigationEvent(sourceURL: wv.state.currentUrl, type: .load))
            guard let snippetStore = wv.snippetStore else {
                wv.setNavigationRequest(load(webView: webView), coordinator: coordinator)
                return
            }

            resourceDownloadHandler.loadNewStore(
                snippetStore,
                onSuccess: { content in
                    let responseUrl = (initialUrl ?? content?.responseUrl) ?? self.wv.targetURL
                    if let content {
                        let navigation = self.createAndLoadURLRequest(for: responseUrl, using: snippetStore.snippet, with: content, in: webView)
                        self.wv.setNavigationRequest(navigation, coordinator: coordinator)
                    }
                },
                shouldCancel: { self.wv.shouldCancelNavigation(webView: webView, coordinator: coordinator) },
                onError: { err in
                    self.wv.handleError(for: webView, using: coordinator, error: err)
                }
            )

            return
        }

        if behaveAsSPA {
            let snippet = wv.snippet
            wv.setNavigationEvent(TWSNavigationEvent(sourceURL: wv.state.currentUrl, type: .spa))
            let snippetToReload = TWSSnippet(id: "reloadSnippet", target: url, dynamicResources: snippet.dynamicResources, visibility: snippet.visibility, engine: snippet.engine, headers: snippet.headers)

            let store: StoreOf<TWSSnippetFeature> = .init(
                initialState: TWSSnippetFeature.State(snippet: snippetToReload),
                reducer: { TWSSnippetFeature() })

            store.send(.business(.setLocalDynamicResources(wv.snippetStore?.localDynamicResources ?? [])))

            resourceDownloadHandler.loadNewStore(
                store,
                onSuccess: { content in
                    if let content, let responseUrl = content.responseUrl {
                        let navigation = self.createAndLoadURLRequest(for: responseUrl, using: snippetToReload, with: content, in: webView)
                        self.wv.setNavigationRequest(navigation, coordinator: coordinator)
                    }
                },
                shouldCancel: { self.wv.shouldCancelNavigation(webView: webView, coordinator: coordinator) },
                onError: { err in
                    self.wv.handleError(for: webView, using: coordinator, error: err)
                }
            )
            return
        } else {
            wv.setNavigationEvent(TWSNavigationEvent(sourceURL: wv.state.currentUrl, type: .nativeLoad))
            let navigation = webView.load(loadUrl)

            wv.setNavigationRequest(navigation, coordinator: coordinator)
        }
    }
        
    func reload(webView: WKWebView, coordinator: WebView.Coordinator, isPullToRefresh: Bool = false) {
        let initialUrl = wv.initialUrl()

        wv.setNavigationEvent(TWSNavigationEvent(sourceURL: wv.state.currentUrl, type: isPullToRefresh ? .pullToRefresh : .reload))

        if !isPullToRefresh {
            wv.updateState(for: webView, loadingState: .loading(progress: 0))
        }

        if initialUrl == wv.state.currentUrl || wv.htmlContent == nil {
            // Reload on initial page
            guard let snippetStore = wv.snippetStore else {
                self.wv.setNavigationRequest(load(webView: webView), coordinator: coordinator, isPullToRefresh: isPullToRefresh)
                return
            }

            resourceDownloadHandler.loadNewStore(
                snippetStore,
                onSuccess: { content in
                    guard let content, let responseUrl = content.responseUrl else {
                        return
                    }
                    let navigation = self.createAndLoadURLRequest(for: responseUrl, using: snippetStore.snippet, with: content, in: webView)
                    self.wv.setNavigationRequest(navigation, coordinator: coordinator, isPullToRefresh: isPullToRefresh)
                },
                shouldCancel: { self.wv.shouldCancelNavigation(webView: webView, coordinator: coordinator) },
                onError: { err in
                    self.wv.handleError(for: webView, using: coordinator, error: err)
                }
            )

            return
        }

        if initialUrl == wv.state.lastLoadedUrl, wv.state.currentUrl != wv.state.lastLoadedUrl {
            guard let currentUrl = wv.state.currentUrl else {
                // if current url does not exist load initial
                wv.setNavigationRequest(load(webView: webView), coordinator: coordinator, isPullToRefresh: isPullToRefresh)
                return
            }
            // Download SPA page and inject resources on reload
            let snippet = wv.snippet
            let snippetToReload = TWSSnippet(id: "reloadSnippet", target: currentUrl, dynamicResources: snippet.dynamicResources, visibility: snippet.visibility, engine: snippet.engine, headers: snippet.headers)

            let store: StoreOf<TWSSnippetFeature> = .init(
                initialState: TWSSnippetFeature.State(snippet: snippetToReload),
                reducer: { TWSSnippetFeature() })

            store.send(.business(.setLocalDynamicResources(wv.snippetStore?.localDynamicResources ?? [])))

            resourceDownloadHandler.loadNewStore(
                store,
                onSuccess: { content in
                    guard let content, let responseUrl = content.responseUrl, let _ = self.wv.state.currentUrl else {
                        return
                    }

                    let navigation = self.createAndLoadURLRequest(for: responseUrl, using: snippetToReload, with: content, in: webView)
                    self.wv.setNavigationRequest(navigation, coordinator: coordinator, isPullToRefresh: isPullToRefresh)
                },
                shouldCancel: { self.wv.shouldCancelNavigation(webView: webView, coordinator: coordinator) },
                onError: { err in
                    self.wv.handleError(for: webView, using: coordinator, error: err)
                    return
                }
            )
            return
        }

        if initialUrl != wv.state.lastLoadedUrl {
            // Normal MPA reload
            if let currentUrl = wv.state.currentUrl, currentUrl != wv.htmlContent?.cachedResponse?.responseUrl {
                let urlRequest = URLRequest(url: currentUrl)
                let navigation = webView.load(urlRequest)
                wv.setNavigationRequest(navigation, coordinator: coordinator, isPullToRefresh: isPullToRefresh)
                return
            }
        }
    }
    
    func cancelContentLoad() {
        resourceDownloadHandler.cancelDownload()
        resourceDownloadHandler.destroyStore()
    }
    
    private func createAndLoadURLRequest(for url: URL, using snippet: TWSSnippet, with content: ResourceResponse, in webView: WKWebView) -> WKNavigation {
        logger.debug("Load from raw HTML: \(String(describing: content.responseUrl?.absoluteString))")
        wv.getNavigationEvent().setDidStartLoading()
        let htmlToLoad = wv._handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippet)
        let urlRequest = URLRequest(url: url)
        return webView.loadSimulatedRequest(urlRequest, responseHTML: htmlToLoad)
    }
}
