////
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

import Foundation
import UIKit
import TWSModels
import SwiftUI
import TWS

@MainActor
public class TWSNotificationsOverlay: NSObject, UISceneDelegate {
    private var hostingControllers: [UIHostingController<NotificationView>] = []

    public static let shared = TWSNotificationsOverlay()
    private var queuedSnippets: [TWSSnippet] = []

    private override init() {
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tryPresentingOverlay),
            name: UIScene.didActivateNotification,
            object: nil)
    }

    public func showOverlay(snippet: TWSSnippet) {
        queuedSnippets.append(snippet)
        tryPresentingOverlay()
    }
    
    @objc private func tryPresentingOverlay() {
        guard let window = getWindowScene() else {
            logger.info("TWSNotificationsOverlay: No active window found")
            return
        }
        
        while let snippet = queuedSnippets.first {
            var controller: UIHostingController<NotificationView>!
            let notificationView = NotificationView(snippet: snippet, dismiss: {
                self.removeHostingController(controller)
            })
            controller = UIHostingController(rootView: notificationView)
            controller.view.backgroundColor = .clear
            controller.view.frame = window.bounds
            controller.view.isUserInteractionEnabled = true
            
            window.addSubview(controller.view)
            window.bringSubviewToFront(controller.view)
            
            hostingControllers.append(controller)
            
            queuedSnippets.remove(at: 0)
        }
    }
    
    private func removeHostingController(_ controller: UIHostingController<NotificationView>) {
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()

        hostingControllers.removeAll { $0 === controller }
    }
    
    private func getWindowScene() -> UIWindow? {
        if let windowScene = UIApplication.shared
            .connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
               return window
        }
        
        return nil
    }
}
