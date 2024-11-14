//
//  TWSView+WebViewCoordinatorNavigatorDelegate.swift
//  TWS
//
//  Created by Miha Hozjan on 13. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import WebKit

extension WebView.Coordinator: TWSViewNavigatorDelegate {

    func navigateBack() {
        assert(webView != nil)
        webView?.goBack()
    }

    func navigateForward() {
        assert(webView != nil)
        webView?.goForward()
    }

    func reload() {
        assert(webView != nil)
        webView?.reload()
    }
}
