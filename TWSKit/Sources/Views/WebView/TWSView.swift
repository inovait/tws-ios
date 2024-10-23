//
//  TWSView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
@_spi(InternalLibraries) import TWSModels

/// The main view to use to display snippets
public struct TWSView<
    LoadingView: View,
    ErrorView: View
>: View {

    @Environment(TWSManager.self) private var manager
    @Environment(\.locationServiceBridge) private var locationServicesBridge
    @Bindable var info: TWSViewInfo

    let snippet: TWSSnippet
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]
    let displayID: String
    let loadingView: () -> LoadingView
    let errorView: (Error) -> ErrorView

    /// Main contructor
    /// - Parameters:
    ///   - snippet: The snippet you want to display
    ///   - displayID: Display id of the view that will be presented. This is needed because the same snippet can be presented on multiple places in the app with different heights. In order for the auto height to work correctly, each loading of the snippet needs it's unique ID to handle this case. The canGoBack and canGoForward functionalities also rely on this ID.
    ///   - info: An observable instance of all the values that ``TWSView`` can manage and update such as page's title, etc.
    ///   - cssOverrides: An array of raw CSS strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    ///   - jsOverrides: An array of raw JS strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    ///   - loadingView: A custom view to display while the snippet is loading
    ///   - errorView: A custom view to display in case the snippet fails to load
    public init(
        snippet: TWSSnippet,
        displayID id: String,
        info: Bindable<TWSViewInfo> = .init(.init()),
        cssOverrides: [TWSRawCSS] = [],
        jsOverrides: [TWSRawJS] = [],
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        @ViewBuilder errorView: @escaping (Error) -> ErrorView
    ) {
        self.snippet = snippet
        self.cssOverrides = cssOverrides
        self.jsOverrides = jsOverrides
        self.displayID = id
        self._info = info
        self.loadingView = loadingView
        self.errorView = errorView
    }

    public var body: some View {
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
            // The internal payload of the target URL has changed ~ redraw is required
            .id(manager.store.snippets.snippets[id: snippet.id]?.updateCount ?? 0)
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

@MainActor
private struct _TWSView: View {

    @Environment(TWSManager.self) private var manager
    @Environment(\.locationServiceBridge) private var locationServiceBridge
    @Environment(\.cameraMicrophoneServiceBridge) private var cameraMicrophoneServiceBridge
    @Environment(\.onDownloadCompleted) private var onDownloadCompleted
    @Bindable var info: TWSViewInfo

    @State var height: CGFloat = 16
    @State private var backCommandID = UUID()
    @State private var forwardCommandID = UUID()
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
        WebView(
            snippet: snippet,
            preloadedResources: manager.store.snippets.preloadedResources,
            locationServicesBridge: locationServiceBridge,
            cameraMicrophoneServicesBridge: cameraMicrophoneServiceBridge,
            cssOverrides: cssOverrides,
            jsOverrides: jsOverrides,
            displayID: displayID,
            isConnectedToNetwork: networkObserver.isConnected,
            dynamicHeight: $height,
            pageTitle: $info.title,
            openURL: openURL,
            backCommandId: backCommandID,
            forwardCommandID: forwardCommandID,
            snippetHeightProvider: manager.snippetHeightProvider,
            navigationProvider: manager.navigationProvider,
            onHeightCalculated: { [weak manager] height in
                assert(Thread.isMainThread)
                manager?.set(height: height, for: snippet, displayID: displayID)
            },
            onUniversalLinkDetected: { [weak manager] url in
                assert(Thread.isMainThread)
                manager?.handleIncomingUrl(url)
            },
            canGoBack: $info.canGoBack,
            canGoForward: $info.canGoForward,
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
