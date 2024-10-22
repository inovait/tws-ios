//
//  WebViewCoordinator+PullToRefresh.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 17. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import WebKit

extension WebView.Coordinator {

    @MainActor
    class PullToRefresh {

        private weak var webView: WKWebView?
        private var refreshRequest: PullToRefreshRequest?

        func enable(on webView: WKWebView) {
            self.webView = webView

            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(
                self,
                action: #selector(_reloadWebView(_:)),
                for: .valueChanged
            )

            webView.scrollView.addSubview(refreshControl)
        }

        func verifyForRefresh(navigation: WKNavigation) -> Bool {
            guard
                let request = refreshRequest,
                request.navigation === navigation
            else { return false }

            request.continuation.resume()
            refreshRequest = nil
            return true
        }

        // MARK: - Helpers

        private func _fire() async {
            guard let webView else { return }

            await withCheckedContinuation { continuation in
                guard let navigation = webView.reload()
                else { continuation.resume(); return }

                refreshRequest = .init(
                    continuation: continuation,
                    navigation: navigation
                )
            }
        }

        // MARK: - Observers

        @objc private func _reloadWebView(_ sender: UIRefreshControl) {
            Task { [weak sender] in
                await _fire()
                sender?.endRefreshing()
            }
        }
    }

    private class PullToRefreshRequest {

        let continuation: CheckedContinuation<Void, Never>
        let navigation: WKNavigation

        init(
            continuation: CheckedContinuation<Void, Never>,
            navigation: WKNavigation
        ) {
            self.continuation = continuation
            self.navigation = navigation
        }
    }
}
