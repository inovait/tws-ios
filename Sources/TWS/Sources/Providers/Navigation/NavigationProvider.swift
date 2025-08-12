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

import UIKit
import WebKit
import SwiftUI

@MainActor
protocol NavigationProvider {
    
    func present(
        webView: WKWebView,
        for navigationAction: WKNavigationAction,
        on originWebView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws(NavigationError)

    func present(
        from: WKWebView,
        alert: UIAlertController,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Bool

    func didClose(
        webView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws(NavigationError)

    func continueNavigation(
        with url: URL,
        from: WKWebView
    ) throws(NavigationError)
    
    func showError(
        errorView: (@MainActor @Sendable (Error, @escaping () -> Void) -> AnyView),
        message: Error,
        on: WKWebView
    ) throws(NavigationError)
    
    func showLoading(
        loadingView: (@MainActor @Sendable (Optional<Double>) -> AnyView),
        on: WKWebView
    ) throws(NavigationError)

}

class NavigationProviderImpl: NavigationProvider {

    private var _presentedVCs = [WKWebView : DestinationInfo]()

    func present(
        webView: WKWebView,
        for navigationAction: WKNavigationAction,
        on originWebView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws(NavigationError) {

        guard let parent = originWebView.parentViewController()
        else { throw NavigationError.parentNotFound }

        guard parent.presentedViewController == nil
        else { throw NavigationError.alreadyPresenting }
        
        let webViewWithErrorOverlay = WebViewWithErrorOverlay(webView: webView, navigationProvider: self, urlRequest: navigationAction.request)
        _presentedVCs[webView] = .init(
            viewController: webViewWithErrorOverlay,
            presentedWebView: webView,
            parentWebView: originWebView
        )

        parent.present(webViewWithErrorOverlay, animated: animated, completion: completion)
    }

    func present(
        from: WKWebView,
        alert: UIAlertController,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Bool {
        guard let parent = from.parentViewController()
        else { completion?(); return false }
        guard parent.presentedViewController == nil
        else { completion?(); return false }

        parent.present(alert, animated: animated, completion: completion)
        return true
    }
    
    func didClose(
        webView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws(NavigationError) {
        guard let viewController = _presentedVCs.removeValue(forKey: webView)?.viewController
        else { throw .viewControllerNotFound }
        viewController.dismiss(animated: animated, completion: completion)
    }

    func continueNavigation(
        with url: URL,
        from: WKWebView
    ) throws(NavigationError) {
        guard let webView = _presentedVCs.values.first(where: { $0.parentWebView == from})?.presentedWebView
        else { throw .presentedViewControllerNotFound }
        
        webView.load(URLRequest(url: url))
    }
    
    func showError(
        errorView: (@MainActor @Sendable (Error, @escaping () -> Void) -> AnyView),
        message: Error,
        on: WKWebView
    ) throws(NavigationError) {
        guard let webView = _presentedVCs.values.first(where: { $0.presentedWebView == on })?.viewController as? WebViewWithErrorOverlay
        else { throw .presentedViewControllerNotFound }
        
        webView.showError(err: message, errorView: errorView)
    }
    
    func showLoading(
        loadingView: (@MainActor @Sendable (Optional<Double>) -> AnyView),
        on: WKWebView) throws(NavigationError) {
            guard let webView = _presentedVCs.values.first(where: { $0.presentedWebView == on })?.viewController as? WebViewWithErrorOverlay
            else { throw .presentedViewControllerNotFound }
            
            webView.showLoadingView(loadingView: loadingView)
    }
}

// MARK: - Helpers

private extension UIView {

    func parentViewController() -> UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

private struct DestinationInfo {

    weak var viewController: UIViewController?
    weak var presentedWebView: WKWebView?
    weak var parentWebView: WKWebView?
}

enum NavigationError: Error {

    case parentNotFound
    case viewControllerNotFound
    case presentedViewControllerNotFound
    case alreadyPresenting
}
