//
//  NavigationProvider.swift
//  TWSKit
//
//  Created by Miha Hozjan on 28. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit
import WebKit

protocol NavigationProvider {

    func present(
        webView: WKWebView,
        on originWebView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws

    func present(
        from: WKWebView,
        alert: UIAlertController,
        animated: Bool,
        completion: (() -> Void)?
    )

    func didClose(
        webView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws

    func continueNavigation(
        with url: URL,
        from: WKWebView
    ) throws
}

class NavigationProviderImpl: NavigationProvider {

    private var _presentedVCs = [WKWebView: DestinationInfo]()

    func present(
        webView: WKWebView,
        on originWebView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws {
        guard let parent = originWebView.parentViewController()
        else { throw NavigationError.parentNotFound }

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
    ) {
        guard let parent = from.parentViewController()
        else { completion?(); return }
        parent.present(alert, animated: animated, completion: completion)
    }

    func didClose(
        webView: WKWebView,
        animated: Bool,
        completion: (() -> Void)?
    ) throws {
        guard let viewController = _presentedVCs.removeValue(forKey: webView)?.viewController
        else { throw NavigationError.viewControllerNotFound }
        viewController.dismiss(animated: animated, completion: completion)
    }

    func continueNavigation(
        with url: URL,
        from: WKWebView
    ) throws {
        guard let webView = _presentedVCs.values.first(where: { $0.parentWebView == from })?.presentedWebView
        else { throw NavigationError.presentedViewControllerNotFound }
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
