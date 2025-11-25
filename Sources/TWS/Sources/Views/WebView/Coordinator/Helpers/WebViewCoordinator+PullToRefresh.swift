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
        
        var refreshRequest: WKNavigation?
        var continuation: CheckedContinuation<Void, Never>?
        private var reload : (() -> Void)? = nil

        func enable(on webView: WKWebView, reload: @escaping () -> Void) {
            self.reload = reload

            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(
                self,
                action: #selector(_reloadWebView(_:)),
                for: .valueChanged
            )

            webView.scrollView.addSubview(refreshControl)
        }
        
        func setNavigationRequest(navigation: WKNavigation?) {
            guard let navigation else { return }
            clearNavigationRequest()
            refreshRequest = navigation
        }
        
        func cancelRefresh() {
            clearNavigationRequest()
        }
        
        func verifyForRefresh(navigation: WKNavigation) -> Bool {
            guard
                let request = refreshRequest,
                request === navigation
            else { return false }
            clearNavigationRequest()
            return true
        }

        // MARK: - Observers
        @objc private func _reloadWebView(_ sender: UIRefreshControl) {
            Task { [weak sender] in
                await withCheckedContinuation { continuation in
                    guard let reload else {
                        continuation.resume()
                        return
                    }
                    reload()
                    
                    self.continuation = continuation
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    sender?.endRefreshing()
                }
            }
        }
        
        // MARK: - Helpers
        private func clearNavigationRequest() {
            continuation?.resume()
            continuation = nil
            refreshRequest = nil
        }
    }
}
