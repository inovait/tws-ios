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

    let url: URL
    let displayID: String
    let isConnectedToNetwork: Bool
    let openURL: URL?
    let backCommandId: UUID
    let forwardCommandID: UUID
    let snippetHeightProvider: SnippetHeightProvider
    let navigationProvider: NavigationProvider
    let onHeightCalculated: (CGFloat) -> Void

    init(
        url: URL,
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
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>,
        loadingState: Binding<TWSLoadingState>
    ) {
        self.url = url
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
        self._dynamicHeight = dynamicHeight
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self._loadingState = loadingState
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: self.url))

        context.coordinator.observe(heightOf: webView)
        updateState(for: webView, loadingState: .loading)

        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            self,
            snippetHeightProvider: snippetHeightProvider,
            navigationProvider: navigationProvider
        )
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
}
