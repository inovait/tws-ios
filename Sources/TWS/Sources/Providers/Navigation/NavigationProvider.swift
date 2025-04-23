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

@MainActor
protocol NavigationProvider {
    var _presentedVC: DestinationInfo? { get set }
    
    func present(
        webView: WebViewWithErrorOverlay,
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
        animated: Bool,
        completion: (() -> Void)?
    ) throws(NavigationError)

    func continueNavigation(
        with url: URL
    ) throws(NavigationError)

}

class NavigationProviderImpl: NavigationProvider {

    var _presentedVC: DestinationInfo? = nil

    func present(
        webView: WebViewWithErrorOverlay,
        on originWebView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws(NavigationError) {
        guard let parent = originWebView.parentViewController()
        else { throw NavigationError.parentNotFound }

        guard parent.presentedViewController == nil
        else { throw NavigationError.alreadyPresenting }

        let newViewController = UIViewController()
        newViewController.view = webView
        _presentedVC = .init(
            viewController: newViewController,
            presentedWebView: webView,
            parentWebView: originWebView
        )

        parent.present(newViewController, animated: animated, completion: completion)
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
        animated: Bool,
        completion: (() -> Void)?
    ) throws(NavigationError) {
        guard let viewController = _presentedVC?.viewController
        else { throw .viewControllerNotFound }
        viewController.dismiss(animated: animated, completion: completion)
        _presentedVC = nil
    }

    func continueNavigation(
        with url: URL,
    ) throws(NavigationError) {
        guard let presentedWebViewController = _presentedVC?.presentedWebView
        else { throw .presentedViewControllerNotFound }
        
        presentedWebViewController.webView.load(URLRequest(url: url))
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

struct DestinationInfo {

    weak var viewController: UIViewController?
    weak var presentedWebView: WebViewWithErrorOverlay?
    weak var parentWebView: WKWebView?
}

enum NavigationError: Error {

    case parentNotFound
    case viewControllerNotFound
    case presentedViewControllerNotFound
    case alreadyPresenting
}
