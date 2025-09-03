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

import SwiftUI
import WebKit
@_spi(Internals) import TWSModels
internal import ComposableArchitecture
internal import TWSSnippet

struct WebView: UIViewRepresentable {

    @Environment(\.navigator) var navigator
    @Environment(\.interceptor) var interceptor
    @Environment(\.errorView) var errorView
    @Environment(\.loadingView) var loadingView
    @Binding var dynamicHeight: CGFloat
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Bindable var state: TWSViewState
    // This helps distinguish between parent and modal views
    @State var wkWebView: WKWebView? = nil

    var id: String { snippet.id }
    var targetURL: URL { snippet.target }
    let snippet: TWSSnippet
    let snippetStore: StoreOf<TWSSnippetFeature>?
    var htmlContent: ResourceResponse? { snippetStore?.htmlContent }
    let locationServicesBridge: LocationServicesBridge
    let cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge
    let displayID: String
    let isConnectedToNetwork: Bool
    let openURL: URL?
    let snippetHeightProvider: SnippetHeightProvider
    let navigationProvider: NavigationProvider
    let onUniversalLinkDetected: (URL) -> Void
    let downloadCompleted: ((TWSDownloadState) -> Void)?
    let enablePullToRefresh: Bool
    
    private var resourceDownloadHandler: ResourceDownloadHandler = .init()

    init(
        snippet: TWSSnippet,
        snippetStore: StoreOf<TWSSnippetFeature>?,
        locationServicesBridge: LocationServicesBridge,
        cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge,
        displayID: String,
        isConnectedToNetwork: Bool,
        dynamicHeight: Binding<CGFloat>,
        openURL: URL?,
        snippetHeightProvider: SnippetHeightProvider,
        navigationProvider: NavigationProvider,
        onUniversalLinkDetected: @escaping @Sendable @MainActor (URL) -> Void,
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>,
        downloadCompleted: ((TWSDownloadState) -> Void)?,
        state: Bindable<TWSViewState>,
        enablePullToRefresh: Bool
    ) {
        self.snippet = snippet
        self.snippetStore = snippetStore
        self.locationServicesBridge = locationServicesBridge
        self.cameraMicrophoneServicesBridge = cameraMicrophoneServicesBridge
        self.displayID = displayID
        self.isConnectedToNetwork = isConnectedToNetwork
        self._dynamicHeight = dynamicHeight
        self.openURL = openURL
        self.snippetHeightProvider = snippetHeightProvider
        self.navigationProvider = navigationProvider
        self.onUniversalLinkDetected = onUniversalLinkDetected
        self._dynamicHeight = dynamicHeight
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self.downloadCompleted = downloadCompleted
        self._state = state
        self.enablePullToRefresh = enablePullToRefresh
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()

        #if DEBUG
        controller.addUserScript(WKUserScript(source: interceptConsoleLogs(controller: controller).value, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        #endif

        // Location Permissions
        let locationPermissionsHandler = _handleLocationPermissions(with: controller)

        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        let agent = (webView.value(forKey: "userAgent") as? String) ?? ""
        webView.customUserAgent = (agent + " " + "TheWebSnippet").trimmingCharacters(in: .whitespacesAndNewlines)
        webView.scrollView.bounces = true
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        navigator.delegate = context.coordinator

        if enablePullToRefresh {
            // process content on reloads
            context.coordinator.pullToRefresh.enable(on: webView) {
                reloadWithProcessedResources(webView: webView, coordinator: context.coordinator)
            }
        }

        if let interceptor {
            controller.add(SPAInterceptorBridge(interceptor: interceptor), name: "intercept")
        }
        
        // Process content on first load
        loadProcessedContent(webView: webView)
        registerWebViewObservers(coordinator: context.coordinator, webView: webView)
        context.coordinator.webView = webView

        logger.debug("INIT WKWebView \(webView.hash) bind to \(id)")
        
        // Binding for permissions
        Task {
            await locationPermissionsHandler.bind(
                webView: webView,
                to: locationServicesBridge
            )
        }
        
        // Hold reference to created WKWebView to know which view is parent and which are presentable children
        Task {
            wkWebView = webView
        }
        
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            self,
            snippetHeightProvider: snippetHeightProvider,
            navigationProvider: navigationProvider,
            downloadCompleted: downloadCompleted,
            interceptor: interceptor,
            state: $state
        )
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        logger.debug("DEINIT WKWebView \(uiView.hash)")
        uiView.navigationDelegate = nil
        uiView.uiDelegate = nil
        uiView.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Save state at the end

        defer {
            context.coordinator.isConnectedToNetwork = isConnectedToNetwork
            context.coordinator.openURL = openURL
        }

        // Regained network connection

        let regainedNetworkConnection = !context.coordinator.isConnectedToNetwork && isConnectedToNetwork
        var stateUpdated: Bool?

        if regainedNetworkConnection, case .failed = state.loadingState {
            if uiView.url == nil {
                updateState(for: uiView, loadingState: .loading(progress: 0.0))
                reloadWithProcessedResources(webView: uiView, coordinator: context.coordinator)
                stateUpdated = true
            } else if !uiView.isLoading {
                reloadWithProcessedResources(webView: uiView, coordinator: context.coordinator)
            }
        }

        // OAuth - Google sign-in

        if
            context.coordinator.redirectedToSafari,
            let openURL,
            openURL != context.coordinator.openURL
            {
            context.coordinator.redirectedToSafari = false
            
            do {
                try navigationProvider.continueNavigation(with: openURL, from: uiView)
            } catch NavigationError.viewControllerNotFound {
                uiView.load(URLRequest(url: openURL))
            } catch {
                logger.err("Failed to continue navigation: \(error)")
            }
        }

        // Update state

        if let stateUpdated, !stateUpdated {
            updateState(for: uiView)
        }
    }

    // MARK: - Helpers
    
    private func registerWebViewObservers(coordinator: Coordinator, webView: WKWebView) {
        coordinator.observe(heightOf: webView)
        coordinator.observe(currentUrlOf: webView)
        coordinator.observe(canGoBackFor: webView)
        coordinator.observe(canGoForwardFor: webView)
        coordinator.observe(loadingProgressOf: webView)
    }

    func updateState(
        for webView: WKWebView,
        loadingState: TWSLoadingState? = nil,
        dynamicHeight: CGFloat? = nil
    ) {
        // Mandatory to hop the thread, because of UI layout change
        DispatchQueue.main.async {
            canGoBack = webView.canGoBack
            canGoForward = webView.canGoForward

            if let dynamicHeight {
                self.dynamicHeight = dynamicHeight
            }

            if let loadingState {
                self.state.loadingState = loadingState
            }
        }
    }
    
    func loadProcessedContent(webView: WKWebView) -> WKNavigation? {
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
            return webView.loadSimulatedRequest(URLRequest(url: content.responseUrl ?? self.targetURL), responseHTML: htmlToLoad)
        }
        
        return nil
    }

    // MARK: - Permissions

    private func _handleLocationPermissions(
        with controller: WKUserContentController
    ) -> JavaScriptLocationAdapter {
        let jsURL = Bundle.module
            .url(forResource: "JavaScriptLocationInjection", withExtension: "js")!
        // swiftlint:disable:next force_try
        let jsContent = try! String(contentsOf: jsURL, encoding: .utf8)
        controller.addUserScript(.init(source: jsContent, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let jsLocationServices = JavaScriptLocationAdapter()
        JavaScriptLocationMessageHandler.addObserver(for: jsLocationServices)
        controller.add(
            JavaScriptLocationMessageHandler(),
            name: "locationHandler"
        )

        return jsLocationServices
    }
    
    private func _handleMustacheProccesing(htmlContentToProcess: String, snippet: TWSSnippet) -> String {
        if snippet.engine == .mustache {
            let mustacheRenderer = MustacheRenderer()
            let convertedProps = mustacheRenderer.convertDictPropsToData(snippet.props)
            return mustacheRenderer.renderMustache(htmlContentToProcess, convertedProps, addDefaultValues: true)
        }
        
        return htmlContentToProcess
    }
    
    func reloadWithProcessedResources(
        webView: WKWebView,
        coordinator: Coordinator
    ) {
        let initialUrl = initialUrl()
        
        if initialUrl == state.currentUrl || htmlContent == nil {
            // Reload on initial page
            guard let snippetStore else {
                coordinator.pullToRefresh.setNavigationRequest(navigation: loadProcessedContent(webView: webView))
                return
            }
            
            resourceDownloadHandler.loadNewStore(
                snippetStore,
                onSuccess: { content in
                    let requestUrl = (initialUrl ?? content?.responseUrl) ?? targetURL
                    if let content {
                        let htmlToLoad = _handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippetStore.snippet)
                        coordinator.pullToRefresh.setNavigationRequest(navigation: webView.loadSimulatedRequest(URLRequest(url: requestUrl), responseHTML: htmlToLoad))
                    }
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
                
                    if let content {
                        logger.debug("Load from raw HTML: \(currentUrl.absoluteString)")
                        let htmlToLoad = _handleMustacheProccesing(htmlContentToProcess: content.data, snippet: snippetToReload)
                        coordinator.pullToRefresh.setNavigationRequest(navigation: webView.loadSimulatedRequest(URLRequest(url: currentUrl), responseHTML: htmlToLoad))
                    }
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
                coordinator.pullToRefresh.setNavigationRequest(navigation: webView.load(URLRequest(url: currentUrl)))
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
                        coordinator.pullToRefresh.setNavigationRequest(navigation: webView.loadSimulatedRequest(URLRequest(url: content.responseUrl ?? url), responseHTML: htmlToLoad))
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
}

extension WebView {
    func shouldChangeLastLoaded() -> Bool {
        return state.lastLoadedUrl == nil || state.lastLoadedUrl != initialUrl()
    }
    
    private func initialUrl() -> URL? {
        return htmlContent?.responseUrl
    }
}
