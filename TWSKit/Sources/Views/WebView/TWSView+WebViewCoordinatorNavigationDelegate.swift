//
//  TWSView+NavigationDelegate.swift
//  TWSKit
//
//  Created by Miha Hozjan on 5. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import WebKit

extension WebView.Coordinator: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        // TODO: maki it better, call shared method
        // MAndatory hop
        DispatchQueue.main.async { [weak self] in
            self?.parent.canGoBack = webView.canGoBack
            self?.parent.canGoForward = webView.canGoForward
        }

        precondition(Thread.isMainThread, "Not allowed to use on non main thread.")
        let cachedScrollHeight: CGFloat?

        if let url = webView.url {
            let hash = WebPageDescription(url)
            cachedScrollHeight = snippetHeightProvider.getHeight(
                for: hash,
                displayID: parent.displayID
            )
        } else {
            cachedScrollHeight = nil
        }

        let scrollHeight = max(cachedScrollHeight ?? webView.scrollView.contentSize.height, 16)
        parent.dynamicHeight = scrollHeight
        return
    }
}
