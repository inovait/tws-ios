//
//  TWSView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSModels

/// The main view to use to display snippets
public struct TWSView<
    LoadingView: View,
    ErrorView: View
>: View {

    let snippet: TWSSnippet
    let handler: TWSManager
    let locationServicesBridge: LocationServicesBridge
    let cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]
    let displayID: String
    let loadingView: () -> LoadingView
    let errorView: (Error) -> ErrorView
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var loadingState: TWSLoadingState
    @Binding var pageTitle: String

    /// Main contructor
    /// - Parameters:
    ///   - snippet: The snippet you want to display
    ///   - locationServicesBridge: Used for providing location services data requested by web browsers
    ///   - cameraMicrophoneBridge: Used for handling camera/microphone services requested by web browser
    ///   - cssOverrides: An array of raw CSS strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    ///   - jsOverrides: An array of raw JS strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    ///   - handler: Pass along the ``TWSManager`` instance that you're using
    ///   - id: Display id of the view that will be presented. This is needed because the same snippet can be presented on multiple places in the app with different heights. In order for the autoheight to work correctly, each loading of the snippet needs it's unique ID to handle this case. The canGoBack and canGoForward functionalities also rely on this ID.
    ///   - canGoBack: Used for lists, when you want to load the previous snippet
    ///   - canGoForward: Used for lists, when you want to load the next snippet
    ///   - loadingState: An instance of ``TWSLoadingState`` that tells you the state of the snippet
    ///   - pageTitle: Once the snippet is loaded, it's title will be set in this variable
    ///   - loadingView: A custom view to display while the snippet is loading
    ///   - errorView: A custom view to display in case the snippet fails to load
    public init(
        snippet: TWSSnippet,
        locationServicesBridge: LocationServicesBridge,
        cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge,
        cssOverrides: [TWSRawCSS] = [],
        jsOverrides: [TWSRawJS] = [],
        using handler: TWSManager,
        displayID id: String,
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>,
        loadingState: Binding<TWSLoadingState>,
        pageTitle: Binding<String> = Binding.constant(""),
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        @ViewBuilder errorView: @escaping (Error) -> ErrorView
    ) {
        self.snippet = snippet
        self.locationServicesBridge = locationServicesBridge
        self.cameraMicrophoneServicesBridge = cameraMicrophoneServicesBridge
        self.cssOverrides = cssOverrides
        self.jsOverrides = jsOverrides
        self.handler = handler
        self.displayID = id
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self._loadingState = loadingState
        self._pageTitle = pageTitle
        self.loadingView = loadingView
        self.errorView = errorView
    }

    public var body: some View {
        ZStack {
            _TWSView(
                snippet: snippet,
                locationServicesBridge: locationServicesBridge,
                cameraMicrophoneServicesBridge: cameraMicrophoneServicesBridge,
                cssOverrides: cssOverrides,
                jsOverrides: jsOverrides,
                using: handler,
                displayID: displayID,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                loadingState: $loadingState,
                pageTitle: $pageTitle
            )
            .frame(width: loadingState.showView ? nil : 0, height: loadingState.showView ? nil : 0)
            .id(snippet.id)
            // The actual URL changed for the same Snippet ~ redraw is required
            .id(snippet.target)
            // The internal payload of the target URL has changed ~ redraw is required
            .id(handler.store.snippets.snippets[id: snippet.id]?.updateCount ?? 0)
            // Only for default location provider; starting on appear/foreground; stopping on disappear/background
            .conditionallyActivateDefaultLocationBehavior(
                locationServicesBridge: locationServicesBridge,
                snippet: snippet,
                displayID: displayID
            )

            ZStack {
                switch loadingState {
                case .idle, .loading:
                    loadingView()

                case .loaded:
                    EmptyView()

                case let .failed(error):
                    errorView(error)
                }
            }
            .frame(width: loadingState.showView ? 0 : nil, height: loadingState.showView ? 0 : nil)
        }
    }
}

@MainActor
private struct _TWSView: View {

    @State var height: CGFloat = 16
    @State private var backCommandID = UUID()
    @State private var forwardCommandID = UUID()
    @State private var networkObserver = NetworkMonitor()
    @State private var openURL: URL?

    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var loadingState: TWSLoadingState
    @Binding var pageTitle: String

    let snippet: TWSSnippet
    let locationServicesBridge: LocationServicesBridge
    let cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]
    let handler: TWSManager
    let displayID: String

    init(
        snippet: TWSSnippet,
        locationServicesBridge: LocationServicesBridge,
        cameraMicrophoneServicesBridge: CameraMicrophoneServicesBridge,
        cssOverrides: [TWSRawCSS],
        jsOverrides: [TWSRawJS],
        using handler: TWSManager,
        displayID id: String,
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>,
        loadingState: Binding<TWSLoadingState>,
        pageTitle: Binding<String>
    ) {
        self.snippet = snippet
        self.locationServicesBridge = locationServicesBridge
        self.cameraMicrophoneServicesBridge = cameraMicrophoneServicesBridge
        self.cssOverrides = cssOverrides
        self.jsOverrides = jsOverrides
        self.handler = handler
        self.displayID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self._loadingState = loadingState
        self._pageTitle = pageTitle
    }

    var body: some View {
        WebView(
            snippet: snippet,
            locationServicesBridge: locationServicesBridge,
            cameraMicrophoneServicesBridge: cameraMicrophoneServicesBridge,
            attachments: snippet.dynamicResources,
            cssOverrides: cssOverrides,
            jsOverrides: jsOverrides,
            displayID: displayID,
            isConnectedToNetwork: networkObserver.isConnected,
            dynamicHeight: $height,
            pageTitle: $pageTitle,
            openURL: openURL,
            backCommandId: backCommandID,
            forwardCommandID: forwardCommandID,
            snippetHeightProvider: handler.snippetHeightProvider,
            navigationProvider: handler.navigationProvider,
            onHeightCalculated: { height in
                Task { @MainActor [weak handler] in
                    assert(Thread.isMainThread)
                    handler?.set(height: height, for: snippet, displayID: displayID)
                }
            },
            onUniversalLinkDetected: { url in
                Task { @MainActor [weak handler] in
                    assert(Thread.isMainThread)
                    handler?.handleIncomingUrl(url)
                }
            },
            canGoBack: $canGoBack,
            canGoForward: $canGoForward,
            loadingState: $loadingState
        )
        // Used for Authentication via Safari
        .onOpenURL { url in openURL = url }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            idealHeight: height
        )
        .onReceive(
            NotificationCenter.default.publisher(for: Notification.Name.Navigation.Back)
        ) { notification in
            guard NotificationBuilder.shouldReact(to: notification, as: snippet, displayID: displayID)
            else { return }
            backCommandID = UUID()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: Notification.Name.Navigation.Forward)
        ) { notification in
            guard NotificationBuilder.shouldReact(to: notification, as: snippet, displayID: displayID)
            else { return }
            forwardCommandID = UUID()
        }
    }
}
