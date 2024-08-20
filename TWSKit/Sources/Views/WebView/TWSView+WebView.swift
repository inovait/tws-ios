//
//  TWSView+Coordinator.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    @Binding var dynamicHeight: CGFloat
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var loadingState: TWSLoadingState
    @Binding var pageTitle: String

    let id = UUID().uuidString.suffix(4)
    let url: URL
    let attachments: [TWSSnippet.Attachment]?
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

    init(
        url: URL,
        attachments: [TWSSnippet.Attachment]?,
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
        loadingState: Binding<TWSLoadingState>
    ) {
        self.url = url
        self.attachments = attachments
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
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        _rawInjectCSS(to: controller, rawCSS: cssOverrides)
        _rawInjectJS(to: controller, rawJS: jsOverrides)
        _urlInjectCSS(to: controller, attachments: attachments)
        _urlInjectJS(to: controller, attachments: attachments)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: self.url))

        context.coordinator.observe(heightOf: webView)
        updateState(for: webView, loadingState: .loading)

        logger.debug("INIT WKWebView \(webView.hash) bind to \(id)")
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            self,
            snippetHeightProvider: snippetHeightProvider,
            navigationProvider: navigationProvider
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
        injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
        forMainFrameOnly: Bool = false
    ) {
        for css in rawCSS {
            let value = css.value
                .replacingOccurrences(of: "\n", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let source = """
            var style = document.createElement('style');
            style.innerHTML = '\(value)';
            document.head.appendChild(style);
            """

            let script = WKUserScript(
                source: source,
                injectionTime: injectionTime,
                forMainFrameOnly: forMainFrameOnly
            )

            controller.addUserScript(script)
        }
    }

    private func _urlInjectCSS(
        to controller: WKUserContentController,
        attachments: [TWSSnippet.Attachment]?,
        injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
        forMainFrameOnly: Bool = false
    ) {
        guard let attachments else { return }
        for attachment in attachments.filter({ $0.type == .css }) {
            let sourceCSS = """
            var link = document.createElement('link');
            link.href = '\(attachment.url.absoluteString)';
            link.rel = 'stylesheet';
            document.head.appendChild(link);
            """

            let script = WKUserScript(
                source: sourceCSS,
                injectionTime: injectionTime,
                forMainFrameOnly: forMainFrameOnly
            )

            controller.addUserScript(script)
        }
    }

    private func _rawInjectJS(
        to controller: WKUserContentController,
        rawJS: [TWSRawJS],
        injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
        forMainFrameOnly: Bool = false
    ) {
        for jvs in rawJS {
            let value = jvs.value
                .replacingOccurrences(of: "\n", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let script = WKUserScript(
                source: value,
                injectionTime: injectionTime,
                forMainFrameOnly: forMainFrameOnly
            )

            controller.addUserScript(script)
        }
    }

    private func _urlInjectJS(
        to controller: WKUserContentController,
        attachments: [TWSSnippet.Attachment]?,
        injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
        forMainFrameOnly: Bool = false
    ) {
        guard let attachments else { return }
        for attachment in attachments.filter({ $0.type == .javascript }) {
            let sourceJS = """
            var script = document.createElement('script');
            script.src = '\(attachment.url.absoluteString)';
            script.type = 'text/javascript';
            document.head.appendChild(script);
            """

            let script = WKUserScript(
                source: sourceJS,
                injectionTime: injectionTime,
                forMainFrameOnly: forMainFrameOnly
            )

            controller.addUserScript(script)
        }
    }
}
