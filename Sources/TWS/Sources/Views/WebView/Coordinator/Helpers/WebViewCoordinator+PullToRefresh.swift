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

        var refreshRequest: PullToRefreshRequest?
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

        func verifyForRefresh(urlRequest: URLRequest) -> Bool {
            guard
                let request = refreshRequest,
                request.navigation.request.url == urlRequest.url
            else { return false }
            
            return true
        }
        
        func verifyForRefresh(navigation: WKNavigation) -> Bool {
            guard
                let request = refreshRequest,
                request.navigation.WKNavigation === navigation
            else { return false }
            request.continuation?.resume()
            refreshRequest = nil
            return true
        }
        
        func setNavigationRequest(navigation: NavigationDetails?) {
            guard let navigation else { return }
            Task {
                await withCheckedContinuation { continuation in
                    refreshRequest = .init(continuation: continuation, navigation: navigation)
                }
            }
        }

        // MARK: - Helpers

        private func refreshWithContinuation() async {
            reload?()
        }

        // MARK: - Observers

        @objc private func _reloadWebView(_ sender: UIRefreshControl) {
            Task { [weak sender] in
                if let reload = reload {
                    await refreshWithContinuation()
                }
                sender?.endRefreshing()
            }
        }
    }

    class PullToRefreshRequest: CustomStringConvertible {
        var description: String {
            "\(self.navigation.WKNavigation)-\(self.navigation.request)"
        }

        var continuation: CheckedContinuation<Void, Never>?
        let navigation: NavigationDetails

        init(
            continuation: CheckedContinuation<Void, Never>?,
            navigation: NavigationDetails
        ) {
            self.continuation = continuation
            self.navigation = navigation
        }
    }
}
