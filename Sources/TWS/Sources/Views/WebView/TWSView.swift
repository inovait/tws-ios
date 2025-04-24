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
@_spi(Internals) import TWSModels
internal import ComposableArchitecture
internal import TWSSnippet
import WebKit

/// The main view to use to display snippets
public struct TWSView: View {

    @Environment(\.presenter) private var presenter
    @Environment(\.locationServiceBridge) private var locationServicesBridge
    @Environment(\.loadingView) private var loadingView
    @Environment(\.preloadingView) private var preloadingView
    @Environment(\.errorView) private var errorView
    @Bindable var state: TWSViewState

    @State private var displayID = UUID().uuidString
    @State private var store: StoreOf<TWSSnippetFeature>?
    @State private var presentedTWSViewState: TWSViewState = .init()

    let snippet: TWSSnippet
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]
    let overrideVisibilty: Bool
    let injectionFilterRegex: String?

    /// Main contructor
    /// - Parameters:
    ///   - snippet: The snippet you want to display
    ///   - state: An observable instance of all the values that ``TWSView`` can manage and update such as page's title, etc.
    ///   - cssOverrides: An array of raw CSS strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    ///   - jsOverrides: An array of raw JS strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    ///   - injectionFilterRegex: A regex deciding whether to inject snippets dynamic resources for certain URL or not. Dynamic resources get injected for a URL when it matches the regex . By default resources are injected only in to the target URL page of the snippet.
    public init(
        snippet: TWSSnippet,
        state: Bindable<TWSViewState> = .init(.init(loadingState: .loaded)),
        cssOverrides: [TWSRawCSS] = [],
        jsOverrides: [TWSRawJS] = [],
        overrideVisibilty: Bool = false,
        injectionFilterRegex: String? = nil
    ) {
        self.snippet = snippet
        self.cssOverrides = cssOverrides
        self.jsOverrides = jsOverrides
        self.overrideVisibilty = overrideVisibilty
        self._state = state
        self.injectionFilterRegex = injectionFilterRegex
    }

    public var body: some View {
        ZStack {
            @Bindable var childState = presentedTWSViewState
            
            if overrideVisibilty || presenter.isVisible(snippet: snippet) {
                if let store = store, store.preloaded == false && !overrideVisibilty {
                    preloadingView()
                        .onAppear {
                            store.send(.view(.openedTWSView))
                        }
                } else {
                    ZStack {
                        _TWSView(
                            snippet: snippet,
                            cssOverrides: cssOverrides,
                            jsOverrides: jsOverrides,
                            displayID: displayID,
                            state: $state,
                            injectionFilterRegex: injectionFilterRegex
                        )
                        .id(snippet.id)
                        // The actual URL changed for the same Snippet ~ redraw is required
                        .id(snippet.target)
                        // Engine type changed, mustache has to be reprocessed
                        .id(snippet.engine)
                        // Snippet properties have updated, mustache has to be reprocessed
                        .id(snippet.props)
                        // The payload of dynamic resources can change
                        .id(presenter.resourcesHash(for: snippet))
                        // The HTML payload can change
                        .id(presenter.preloadedResources[TWSSnippet.Attachment(url: snippet.target, contentType: .html)])
                        // Only for default location provider; starting on appear/foreground; stopping on disappear/background
                        .conditionallyActivateDefaultLocationBehavior(
                            locationServicesBridge: locationServicesBridge,
                            snippet: snippet,
                            displayID: displayID
                        )
                        
                        ZStack {
                            switch state.loadingState {
                            case .idle, .loading:
                                loadingView()
                                
                            case .loaded:
                                EmptyView()
                                
                            case let .failed(error):
                                errorView(error)
                            }
                        }
                        .frame(width: state.loadingState.showView ? 0 : nil, height: state.loadingState.showView ? 0 : nil)
                    }
                }
            }
        }
        .onAppear {
            store = presenter.store(forSnippetID: snippet.id)
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
    @Bindable var state: TWSViewState
    
    @State var height: CGFloat = 16
    @State private var networkObserver = NetworkMonitor()
    @State private var openURL: URL?

    let snippet: TWSSnippet
    let cssOverrides: [TWSRawCSS]
    let jsOverrides: [TWSRawJS]
    let displayID: String
    let injectionFilterRegex: String?

    init(
        snippet: TWSSnippet,
        cssOverrides: [TWSRawCSS],
        jsOverrides: [TWSRawJS],
        displayID id: String,
        state: Bindable<TWSViewState>,
        injectionFilterRegex: String?
    ) {
        self.snippet = snippet
        self.cssOverrides = cssOverrides
        self.jsOverrides = jsOverrides
        self.displayID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self._state = state
        self.injectionFilterRegex = injectionFilterRegex
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
            openURL: openURL,
            snippetHeightProvider: presenter.heightProvider,
            navigationProvider: presenter.navigationProvider,
            onUniversalLinkDetected: { url in
                assert(Thread.isMainThread)
                presenter.handleIncomingUrl(url)
            },
            canGoBack: $navigator.canGoBack,
            canGoForward: $navigator.canGoForward,
            downloadCompleted: onDownloadCompleted,
            state: $state,
            injectionFilterRegex: injectionFilterRegex
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
