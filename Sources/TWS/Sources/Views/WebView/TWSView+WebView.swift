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

struct WebView: UIViewRepresentable {

    @Environment(\.navigator) var navigator
    @Environment(\.interceptor) var interceptor
    @Binding var dynamicHeight: CGFloat
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Bindable var state: TWSViewState
    @Binding var presentedUrl: URL?
    @Binding var parentSnippet: TWSSnippet?

    var id: String { snippet.id }
    var targetURL: URL { snippet.target }
    let snippet: TWSSnippet
    let preloadedResources: [TWSSnippet.Attachment: ResourceResponse]
    let locationServicesBridge: LocationServicesBridge
    let cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]
    let displayID: String
    let isConnectedToNetwork: Bool
    let openURL: URL?
    let snippetHeightProvider: SnippetHeightProvider
    let navigationProvider: NavigationProvider
    let onUniversalLinkDetected: (URL) -> Void
    let downloadCompleted: ((TWSDownloadState) -> Void)?

    init(
        snippet: TWSSnippet,
        preloadedResources: [TWSSnippet.Attachment: ResourceResponse],
        locationServicesBridge: LocationServicesBridge,
        cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge,
        cssOverrides: [TWSRawCSS],
        jsOverrides: [TWSRawJS],
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
        presentedUrl: Binding<URL?>,
        parentSnippet: Binding<TWSSnippet?>
    ) {
        self.snippet = snippet
        self.preloadedResources = preloadedResources
        self.locationServicesBridge = locationServicesBridge
        self.cameraMicrophoneServicesBridge = cameraMicrophoneServicesBridge
        self.cssOverrides = cssOverrides
        self.jsOverrides = jsOverrides
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
        self._presentedUrl = presentedUrl
        self._parentSnippet = parentSnippet
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()

        #if DEBUG
        _rawInjectJS(
            to: controller,
            rawJS: [interceptConsoleLogs(controller: controller)],
            andPreloadedResources: [:],
            forSnippet: snippet
        )
        #endif

        _rawInjectCSS(
            to: controller,
            rawCSS: cssOverrides,
            andPreloadedAttachments: preloadedResources,
            forSnippet: snippet
        )

        _rawInjectJS(
            to: controller,
            rawJS: jsOverrides,
            andPreloadedResources: preloadedResources,
            forSnippet: snippet
        )

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
        
        if parentSnippet == nil {
            navigator.delegate = context.coordinator
        }

        // process content on reloads
        context.coordinator.pullToRefresh.enable(on: webView) {
            if let currentUrl = state.currentUrl, currentUrl != targetURL {
                webView.load(URLRequest(url: currentUrl))
            } else {
                loadProcessedContent(webView: webView)
            }
        }

        if let navigationAction = state.navigationAction {
            webView.load(navigationAction.request)
        } else {
            // Process content on first load
            loadProcessedContent(webView: webView)
        }
        
        context.coordinator.observe(heightOf: webView)
        context.coordinator.observe(currentUrlOf: webView)
        context.coordinator.webView = webView

        updateState(for: webView, loadingState: .loading)

        logger.debug("INIT WKWebView \(webView.hash) bind to \(id)")
        
        // Binding for permissions
        Task {
            await locationPermissionsHandler.bind(
                webView: webView,
                to: locationServicesBridge
            )
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
            presentedUrl: $presentedUrl,
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
                updateState(for: uiView, loadingState: .loading)
                uiView.load(URLRequest(url: self.targetURL))
                stateUpdated = true
            } else if !uiView.isLoading {
                uiView.reload()
            }
        }

        // OAuth - Google sign-in

        if
            context.coordinator.redirectedToSafari,
            let openURL,
            openURL != context.coordinator.openURL {

            context.coordinator.redirectedToSafari = false
            
            if parentSnippet != nil {
                do {
                    print("URL to open \(openURL)")
                    try uiView.load(URLRequest(url: openURL))
                } catch {
                    print("load failed: \(error)")
                }
            }
        }

        // Update state

        if let stateUpdated, !stateUpdated {
            updateState(for: uiView)
        }
    }

    // MARK: - Helpers

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
    
    private func loadProcessedContent(webView: WKWebView) {
        let key = TWSSnippet.Attachment(url: targetURL, contentType: .html)
        
        if let preloaded = preloadedResources[key] {
            logger.debug("Load from raw HTML: \(targetURL.absoluteString)")
            let htmlToLoad = _handleMustacheProccesing(preloadedHTML: preloaded.data, snippet: snippet)
            webView.loadSimulatedRequest(URLRequest(url: preloaded.responseUrl ?? self.targetURL), responseHTML: htmlToLoad)
        } else {
            logger.debug("Load from url: \(targetURL.absoluteString)")
            var urlRequest = URLRequest(url: self.targetURL)
            snippet.headers?.forEach { header in
                urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
            }
            webView.load(urlRequest)
        }
    }

    private func _rawInjectCSS(
        to controller: WKUserContentController,
        rawCSS: [TWSRawCSS],
        andPreloadedAttachments resources: [TWSSnippet.Attachment: ResourceResponse],
        forSnippet snippet: TWSSnippet,
        injectionTime: WKUserScriptInjectionTime = .atDocumentStart,
        forMainFrameOnly: Bool = false
    ) {
        precondition(Thread.isMainThread, "Injecting JS must be done on the main thread.")

        let snippetAttachmentsURLs = snippet.dynamicResources?.map(\.url) ?? []
        let preloaded = resources
            .filter { $0.key.contentType == .css }
            .filter { snippetAttachmentsURLs.contains($0.key.url) }
            .map { TWSRawCSS($0.value.data) }

        for css in preloaded + rawCSS {
            let value = css.value
                // This is important, otherwise it won't work
                .replacingOccurrences(of: "\n", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let source = """
            var style = document.createElement('style');
            style.innerHTML = '\(value)';
            var D = document;
            var targ  = D.getElementsByTagName('head')[0] || D.body || D.documentElement;
            targ.appendChild(style);
            """

            let script = WKUserScript(
                source: source,
                injectionTime: injectionTime,
                forMainFrameOnly: forMainFrameOnly
            )

            controller.addUserScript(script)
        }
    }

    private func _rawInjectJS(
        to controller: WKUserContentController,
        rawJS: [TWSRawJS],
        andPreloadedResources resources: [TWSSnippet.Attachment: ResourceResponse],
        forSnippet snippet: TWSSnippet,
        injectionTime: WKUserScriptInjectionTime = .atDocumentStart,
        forMainFrameOnly: Bool = false
    ) {
        precondition(Thread.isMainThread, "Injecting JS must be done on the main thread.")

        let snippetAttachmentsURLs = snippet.dynamicResources?.map(\.url) ?? []
        let preloaded = resources
            .filter { $0.key.contentType == .javascript }
            .filter { snippetAttachmentsURLs.contains($0.key.url) }
            .map { TWSRawJS($0.value.data) }

        for jvs in preloaded + rawJS {
            let value = jvs.value
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let script = WKUserScript(
                source: value,
                injectionTime: injectionTime,
                forMainFrameOnly: forMainFrameOnly
            )

            controller.addUserScript(script)
        }
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
        controller.add(
            JavaScriptLocationMessageHandler(adapter: jsLocationServices),
            name: "locationHandler"
        )

        return jsLocationServices
    }
    
    private func _handleMustacheProccesing(preloadedHTML: String, snippet: TWSSnippet) -> String {
        if snippet.engine == .mustache {
            let mustacheRenderer = MustacheRenderer()
            let convertedProps = mustacheRenderer.convertDictPropsToData(snippet.props)
            return mustacheRenderer.renderMustache(preloadedHTML, convertedProps, addDefaultValues: true)
        }
        
        return preloadedHTML
    }
}
