//
//  TWSView+WebViewCoordinator.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import WebKit

extension WebView {

    @MainActor
    class Coordinator: NSObject {

        var parent: WebView
        var heightObserver: NSKeyValueObservation?
        var backCommandId: UUID?
        var forwardCommandID: UUID?
        var isConnectedToNetwork = true
        var redirectedToSafari = false
        var openURL: URL?
        var downloadInfo = TWSDownloadInfo()

        let id = UUID().uuidString.suffix(4)
        let snippetHeightProvider: SnippetHeightProvider
        let navigationProvider: NavigationProvider
        let downloadCompleted: ((TWSDownloadState) -> Void)?

        init(
            _ parent: WebView,
            snippetHeightProvider: SnippetHeightProvider,
            navigationProvider: NavigationProvider,
            downloadCompleted: ((TWSDownloadState) -> Void)?
        ) {
            self.parent = parent
            self.snippetHeightProvider = snippetHeightProvider
            self.navigationProvider = navigationProvider
            self.downloadCompleted = downloadCompleted
            logger.debug("INIT Coordinator for WKWebView \(parent.id)-\(id)")
        }

        deinit {
            heightObserver?.invalidate()
            heightObserver = nil
            logger.debug("DEINIT Coordinator for WKWebView \(id)")
        }

        // MARK: - Internals

        func observe(heightOf webView: WKWebView) {
            var prevHeight: CGFloat = .zero
            let displayID = parent.displayID

            heightObserver = webView.scrollView.observe(
                \.contentSize,
                options: [.new]
            ) { [weak self, parent] _, change in
                MainActor.assumeIsolated {
                    guard
                        let self = self,
                        let newHeight = change.newValue?.height,
                        newHeight != prevHeight
                    else { return }

                    prevHeight = newHeight
                    if let currentPage = webView.url {
                        let hash = WebPageDescription(currentPage)
                        self.snippetHeightProvider.set(
                            height: newHeight,
                            for: hash,
                            displayID: self.parent.displayID
                        )

                        if hash == WebPageDescription(self.parent.url) {
                            assert(displayID == parent.displayID)
                            self.parent.onHeightCalculated(newHeight)
                        }
                    }

                    // Mandatory to hop the thread, because of UI layout change
                    DispatchQueue.main.async { [weak self] in
                        self?.parent.dynamicHeight = newHeight
                    }
                }
            }
        }
    }
}
