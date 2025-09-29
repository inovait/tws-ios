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
    @Environment(\.navigator) private var navigator
    @Bindable var bindableState: TWSViewState
    @State var internalState = TWSViewState()

    @State private var displayID = UUID().uuidString
    @State private var store: StoreOf<TWSSnippetFeature>?

    let snippet: TWSSnippet
    let overrides: [TWSRawDynamicResource]
    let overrideVisibilty: Bool
    let enablePullToRefresh: Bool

    /// Main contructor
    /// - Parameters:
    ///   - snippet: The snippet you want to display
    ///   - state: An observable instance of all the values that ``TWSView`` can manage and update such as page's title, etc.
    ///   - overrides: An array of raw CSS/JavaScript strings that are injected in the web view. The new lines will be removed so make sure the string is valid (the best is if you use a minified version.
    ///   - enablePullToRefresh: Flag used to determine whether pull to refresh action should be enabled.
    public init(
        snippet: TWSSnippet,
        state: Bindable<TWSViewState> = .init(TWSViewState.defaultState()),
        overrides: [TWSRawDynamicResource] = [],
        overrideVisibilty: Bool = false,
        enablePullToRefresh: Bool = false
    ) {
        self.snippet = snippet
        self.overrides = overrides
        self.overrideVisibilty = overrideVisibilty
        self._bindableState = state
        self.enablePullToRefresh = enablePullToRefresh
    }

    public var body: some View {
        @Bindable var state = if (bindableState.isProvided) { bindableState } else { internalState }
        
        return ZStack {
            if overrideVisibilty || presenter.isVisible(snippet: snippet) {
                if let store = store, store.contentDownloaded == false && !overrideVisibilty {
                    preloadingView()
                        .onAppear {
                            store.send(.view(.openedTWSView))
                        }
                } else {
                    ZStack {
                        _TWSView(
                            snippet: snippet,
                            displayID: displayID,
                            state: $state,
                            enablePullToRefresh: enablePullToRefresh
                        )
                        .id(snippet.id)
                        // The actual URL changed for the same Snippet ~ redraw is required
                        .id(snippet.target)
                        // Engine type changed, mustache has to be reprocessed
                        .id(snippet.engine)
                        // Snippet properties have updated, mustache has to be reprocessed
                        .id(snippet.props)
                        // Only for default location provider; starting on appear/foreground; stopping on disappear/background
                        .conditionallyActivateDefaultLocationBehavior(
                            locationServicesBridge: locationServicesBridge,
                            snippet: snippet,
                            displayID: displayID
                        )
                        // Check if initial load failed
                        .onAppear {
                            if let err = store?.error {
                                state.loadingState = .failed(err)
                            }
                        }
                        // Check if reload failed
                        .onChange(of: store?.error) { _, new in
                            if let err = new {
                                state.loadingState = .failed(err)
                            }
                        }
                        
                        ZStack {
                            switch state.loadingState {
                            case .idle:
                                loadingView(nil)
                            case .loading(let progress):
                                loadingView(progress)
                                
                            case .loaded:
                                EmptyView()
                                
                            case let .failed(error):
                                errorView(error) { navigator.reload() }
                            }
                        }
                        .frame(width: state.loadingState.showView ? 0 : nil, height: state.loadingState.showView ? 0 : nil)
                    }
                }
            }
        }
        .onAppear {
            // NoopPresenter is used for local snippets
            (presenter as? NoopPresenter)?.saveLocalSnippet(snippet)
            store = presenter.store(forSnippetID: snippet.id)
            store?.send(.business(.setLocalDynamicResources(overrides)))
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
    @Environment(\.isOverlay) private var isOverlay
    @Bindable var state: TWSViewState
    
    @State var height: CGFloat = 16
    @State private var networkObserver = NetworkMonitor()
    @State private var openURL: URL?

    let snippet: TWSSnippet
    let displayID: String
    let enablePullToRefresh: Bool
    
    init(
        snippet: TWSSnippet,
        displayID id: String,
        state: Bindable<TWSViewState>,
        enablePullToRefresh: Bool
    ) {
        self.snippet = snippet
        self.displayID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self._state = state
        self.enablePullToRefresh = enablePullToRefresh
    }

    var body: some View {
        @Bindable var navigator = navigator
        WebView(
            snippet: snippet,
            snippetStore: presenter.store(forSnippetID: snippet.id),
            locationServicesBridge: locationServiceBridge,
            cameraMicrophoneServicesBridge: cameraMicrophoneServiceBridge,
            displayID: displayID,
            isConnectedToNetwork: networkObserver.isConnected,
            dynamicHeight: $height,
            openURL: openURL,
            snippetHeightProvider: presenter.heightProvider,
            navigationProvider: presenter.navigationProvider,
            canGoBack: $navigator.canGoBack,
            canGoForward: $navigator.canGoForward,
            downloadCompleted: onDownloadCompleted,
            state: $state,
            enablePullToRefresh: enablePullToRefresh
        )
        // onOpenUrl used for Authentication via Safari, wrapped because overlays are opened via UIKit, which should not have onOpenUrl modifier
        .modifier(onOpenURLModifier(enabled: !isOverlay, openUrl: $openURL))
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            idealHeight: height
        )
    }
}
