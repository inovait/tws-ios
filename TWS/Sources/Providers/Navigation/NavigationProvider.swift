//
//  NavigationProvider.swift
//  TWS
//
//  Created by Miha Hozjan on 28. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit
import WebKit

@MainActor
protocol NavigationProvider {

    func present(
        webView: WKWebView,
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
}

class NavigationProviderImpl: NavigationProvider {

    private var _presentedVCs = [WKWebView: DestinationInfo]()

    func present(
        webView: WKWebView,
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
        _presentedVCs[webView] = .init(
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
        guard let webView = _presentedVCs.values.first(where: { $0.parentWebView == from })?.presentedWebView
        else { throw .presentedViewControllerNotFound }
        webView.load(URLRequest(url: url))
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
