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

    class Coordinator: NSObject {

        var parent: WebView
        var heightObserver: NSKeyValueObservation?
        var backCommandId: UUID?
        var forwardCommandID: UUID?
        var isConnectedToNetwork: Bool = true
        let snippetHeightProvider: SnippetHeightProvider

        init(
            _ parent: WebView,
            snippetHeightProvider: SnippetHeightProvider

        ) {
            self.parent = parent
            self.snippetHeightProvider = snippetHeightProvider
        }

        deinit {
            heightObserver?.invalidate()
            heightObserver = nil
        }

        // MARK: - Internals

        func observe(heightOf webView: WKWebView) {
            var prevHeight: CGFloat = .zero
            let displayID = parent.displayID

            heightObserver = webView.scrollView.observe(\.contentSize, options: [.new]) { [weak self] _, change in
                assert(Thread.isMainThread)
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
