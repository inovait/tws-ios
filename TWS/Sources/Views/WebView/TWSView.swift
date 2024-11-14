//
//  TWSView.swift
//  TWS
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
@_spi(Internals) import TWSModels

/// The main view to use to display snippets
public struct TWSView: View {

    @Environment(\.presenter) private var presenter
    @Environment(\.locationServiceBridge) private var locationServicesBridge
    @Environment(\.loadingView) private var loadingView
    @Environment(\.errorView) private var errorView
    @Bindable var info: TWSViewInfo

    @State private var displayID = UUID().uuidString

    let snippet: TWSSnippet
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]

    /// Main contructor
    /// - Parameters:
    ///   - snippet: The snippet you want to display
    ///   - info: An observable instance of all the values that ``TWSView`` can manage and update such as page's title, etc.
    ///   - cssOverrides: An array of raw CSS strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    ///   - jsOverrides: An array of raw JS strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    public init(
        snippet: TWSSnippet,
        info: Bindable<TWSViewInfo> = .init(.init(loadingState: .loaded)),
        cssOverrides: [TWSRawCSS] = [],
        jsOverrides: [TWSRawJS] = []
    ) {
        self.snippet = snippet
        self.cssOverrides = cssOverrides
        self.jsOverrides = jsOverrides
        self._info = info
    }

    public var body: some View {
        if presenter.isVisible(snippet: snippet) {
            ZStack {
                _TWSView(
                    snippet: snippet,
                    cssOverrides: cssOverrides,
                    jsOverrides: jsOverrides,
                    displayID: displayID,
                    info: $info
                )
                .frame(width: info.loadingState.showView ? nil : 0, height: info.loadingState.showView ? nil : 0)
                .id(snippet.id)
                // The actual URL changed for the same Snippet ~ redraw is required
                .id(snippet.target)
                // The payload of dynamic resources can change
                .id(presenter.resourcesHash(for: snippet))
                // The internal payload of the target URL has changed ~ redraw is required
                .id(presenter.updateCount(for: snippet))
                // Only for default location provider; starting on appear/foreground; stopping on disappear/background
                .conditionallyActivateDefaultLocationBehavior(
                    locationServicesBridge: locationServicesBridge,
                    snippet: snippet,
                    displayID: displayID
                )

                ZStack {
                    switch info.loadingState {
                    case .idle, .loading:
                        loadingView()

                    case .loaded:
                        EmptyView()

                    case let .failed(error):
                        errorView(error)
                    }
                }
                .frame(width: info.loadingState.showView ? 0 : nil, height: info.loadingState.showView ? 0 : nil)
            }
        }
    }
}

@MainActor
private struct _TWSView: View {

    @Environment(\.presenter) private var presenter
    @Environment(\.locationServiceBridge) private var locationServiceBridge
    @Environment(\.cameraMicrophoneServiceBridge) private var cameraMicrophoneServiceBridge
    @Environment(\.onDownloadCompleted) private var onDownloadCompleted
    @Environment(\.navigator) private var navigator
    @Environment(\.interceptor) private var interceptor
    @Bindable var info: TWSViewInfo

    @State var height: CGFloat = 16
    @State private var networkObserver = NetworkMonitor()
    @State private var openURL: URL?

    let snippet: TWSSnippet
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]
    let displayID: String

    init(
        snippet: TWSSnippet,
        cssOverrides: [TWSRawCSS],
        jsOverrides: [TWSRawJS],
        displayID id: String,
        info: Bindable<TWSViewInfo>
    ) {
        self.snippet = snippet
        self.cssOverrides = cssOverrides
        self.jsOverrides = jsOverrides
        self.displayID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self._info = info
    }

    var body: some View {
        @Bindable var navigator = navigator
        WebView(
            snippet: snippet,
            preloadedResources: presenter.preloadedResources,
            locationServicesBridge: locationServiceBridge,
            cameraMicrophoneServicesBridge: cameraMicrophoneServiceBridge,
            cssOverrides: cssOverrides,
            jsOverrides: jsOverrides,
            displayID: displayID,
            isConnectedToNetwork: networkObserver.isConnected,
            dynamicHeight: $height,
            pageTitle: $info.title,
            openURL: openURL,
            snippetHeightProvider: presenter.heightProvider,
            navigationProvider: presenter.navigationProvider,
            onUniversalLinkDetected: { url in
                assert(Thread.isMainThread)
                presenter.handleIncomingUrl(url)
            },
            canGoBack: $navigator.canGoBack,
            canGoForward: $navigator.canGoForward,
            loadingState: $info.loadingState,
            downloadCompleted: onDownloadCompleted
        )
        // Used for Authentication via Safari
        .onOpenURL { url in openURL = url }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            idealHeight: height
        )
    }
}
