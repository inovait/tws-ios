//
//  TWSView+Coordinator.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import WebKit
@_spi(InternalLibraries) import TWSModels

struct WebView: UIViewRepresentable {

    @Binding var dynamicHeight: CGFloat
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var loadingState: TWSLoadingState
    @Binding var pageTitle: String

    var id: UUID { snippet.id }
    var url: URL { snippet.target }
    let snippet: TWSSnippet
    let preloadedResources: [TWSSnippet.Attachment: String]
    let locationServicesBridge: LocationServicesBridge
    let cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]
    let displayID: String
    let isConnectedToNetwork: Bool
    let openURL: URL?
    let backCommandId: UUID
    let forwardCommandID: UUID
    let snippetHeightProvider: SnippetHeightProvider
    let navigationProvider: NavigationProvider
    let onHeightCalculated: (CGFloat) -> Void
    let onUniversalLinkDetected: (URL) -> Void
    let downloadCompleted: ((TWSDownloadState) -> Void)?

    init(
        snippet: TWSSnippet,
        preloadedResources: [TWSSnippet.Attachment: String],
        locationServicesBridge: LocationServicesBridge,
        cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge,
        cssOverrides: [TWSRawCSS],
        jsOverrides: [TWSRawJS],
        displayID: String,
        isConnectedToNetwork: Bool,
        dynamicHeight: Binding<CGFloat>,
        pageTitle: Binding<String>,
        openURL: URL?,
        backCommandId: UUID,
        forwardCommandID: UUID,
        snippetHeightProvider: SnippetHeightProvider,
        navigationProvider: NavigationProvider,
        onHeightCalculated: @escaping @Sendable (CGFloat) -> Void,
        onUniversalLinkDetected: @escaping @Sendable (URL) -> Void,
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>,
        loadingState: Binding<TWSLoadingState>,
        downloadCompleted: ((TWSDownloadState) -> Void)?
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
        self._pageTitle = pageTitle
        self.openURL = openURL
        self.backCommandId = backCommandId
        self.forwardCommandID = forwardCommandID
        self.snippetHeightProvider = snippetHeightProvider
        self.navigationProvider = navigationProvider
        self.onHeightCalculated = onHeightCalculated
        self.onUniversalLinkDetected = onUniversalLinkDetected
        self._dynamicHeight = dynamicHeight
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self._loadingState = loadingState
        self.downloadCompleted = downloadCompleted
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

        //

        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        let agent = (webView.value(forKey: "userAgent") as? String) ?? ""
        webView.customUserAgent = (agent + " " + "TheWebSnippet").trimmingCharacters(in: .whitespacesAndNewlines)
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: self.url))

        context.coordinator.observe(heightOf: webView)
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
            downloadCompleted: downloadCompleted
        )
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        logger.debug("DEINIT WKWebView \(uiView.hash)")
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {

        // Save state at the end

        defer {
            context.coordinator.backCommandId = backCommandId
            context.coordinator.forwardCommandID = forwardCommandID
            context.coordinator.isConnectedToNetwork = isConnectedToNetwork
            context.coordinator.openURL = openURL
        }

        // Go back & Go forward

        if
            let prevBackCommand = context.coordinator.backCommandId,
            prevBackCommand != backCommandId {
            uiView.goBack()
        }

        if
            let prevForwardCommandID = context.coordinator.forwardCommandID,
            prevForwardCommandID != forwardCommandID {
            uiView.goForward()
        }

        // Regained network connection

        let regainedNetworkConnection = !context.coordinator.isConnectedToNetwork && isConnectedToNetwork
        var stateUpdated: Bool?

        if regainedNetworkConnection, case .failed = loadingState {
            if uiView.url == nil {
                updateState(for: uiView, loadingState: .loading)
                uiView.load(URLRequest(url: self.url))
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
                self.loadingState = loadingState
            }
        }
    }

    private func _rawInjectCSS(
        to controller: WKUserContentController,
        rawCSS: [TWSRawCSS],
        andPreloadedAttachments resources: [TWSSnippet.Attachment: String],
        forSnippet snippet: TWSSnippet,
        injectionTime: WKUserScriptInjectionTime = .atDocumentStart,
        forMainFrameOnly: Bool = false
    ) {
        precondition(Thread.isMainThread, "Injecting JS must be done on the main thread.")

        let snippetAttachmentsURLs = snippet.dynamicResources?.map(\.url) ?? []
        let preloaded = resources
            .filter { $0.key.contentType == .css }
            .filter { snippetAttachmentsURLs.contains($0.key.url) }
            .map { TWSRawCSS($0.value) }

        for css in preloaded + rawCSS {
            let value = css.value
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
        andPreloadedResources resources: [TWSSnippet.Attachment: String],
        forSnippet snippet: TWSSnippet,
        injectionTime: WKUserScriptInjectionTime = .atDocumentStart,
        forMainFrameOnly: Bool = false
    ) {
        precondition(Thread.isMainThread, "Injecting JS must be done on the main thread.")

        let snippetAttachmentsURLs = snippet.dynamicResources?.map(\.url) ?? []
        let preloaded = resources
            .filter { $0.key.contentType == .javascript }
            .filter { snippetAttachmentsURLs.contains($0.key.url) }
            .map { TWSRawJS($0.value) }

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
        let jsURL = Bundle(for: JavaScriptLocationAdapter.self)
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
}
