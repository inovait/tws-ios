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

import WebKit

extension WebView.Coordinator {

    @MainActor
    class PullToRefresh {

        private weak var webView: WKWebView?
        private var refreshRequest: PullToRefreshRequest?

        private var reload : (() -> Void)? = nil


        func enable(on webView: WKWebView, reload: @escaping () -> Void) {
            self.reload = reload
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

            request.continuation?.resume()
            refreshRequest = nil
            return true
        }
        
        func setNavigationRequest(navigation: WKNavigation?) {
            guard let navigation else { return }
            refreshRequest = .init(continuation: nil, navigation: navigation)
        }

        // MARK: - Helpers

        private func refreshWithContinuation() async {
            await withCheckedContinuation { continuation in
                guard let reload = reload
                else { continuation.resume(); return }
                
                reload()
                continuation.resume()
            }
        }
        
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
                if let reload = reload {
                    await refreshWithContinuation()
                } else {
                    await _fire()
                }
                sender?.endRefreshing()
            }
        }
    }

    private class PullToRefreshRequest {

        let continuation: CheckedContinuation<Void, Never>?
        let navigation: WKNavigation

        init(
            continuation: CheckedContinuation<Void, Never>?,
            navigation: WKNavigation
        ) {
            self.continuation = continuation
            self.navigation = navigation
        }
    }
}
