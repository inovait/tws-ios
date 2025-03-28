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

    func present(
        from: WKWebView,
        alert: UIAlertController,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Bool

}

class NavigationProviderImpl: NavigationProvider {

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
