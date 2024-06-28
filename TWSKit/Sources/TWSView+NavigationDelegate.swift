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
        webView.evaluateJavaScript("document.title") { (result, error) in
            if let title = result as? String, error == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.pageTitle = title
                }
            }
        }
        Task { [weak self] in try? await self?._updateHeight(webView) }
    }

    // MARK: - Helpers

    @MainActor
    @discardableResult
    private func _updateHeight(_ webView: WKWebView) async throws -> Bool {
        let scriptBody = #"""
        document.readyState === 'complete' ? (() => {
            const bodyHeight = document.body.scrollHeight;
            const header = document.querySelector('header');
            const headerHeight = header ? header.scrollHeight : 0;
            const footer = document.querySelector('footer');
            const footerHeight = footer ? footer.scrollHeight : 0;
            return bodyHeight + headerHeight + footerHeight;
        })() : -1;
        """#

        let result = try await webView.evaluateJavaScript(scriptBody)
        guard let height = result as? CGFloat else { return false }

        if height <= 0 {
            _scheduleHeightUpdate(webView)
            return false
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.parent.dynamicHeight = height
            }

            return true
        }
    }

    private func _scheduleHeightUpdate(_ webView: WKWebView) {
        heightWorkItem?.cancel()
        heightWorkItem = .init { [weak self] in
            Task { [webView, weak self] in
                do {
                    try await self?._updateHeight(webView)
                } catch {
                    assertionFailure("\(error)")
                }
            }
        }

        guard let heightWorkItem else { fatalError("Can not be nil") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: heightWorkItem)
    }
}
