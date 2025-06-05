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
public class TWSNotificationsOverlay {
    private var hostingController: UIHostingController<NotificationView>?

    public static let shared = TWSNotificationsOverlay()

    private init() {}

    public func showOverlay(snippet: TWSSnippet) {
        self.dismissOverlay()
        guard let window = getWindowScene() else {
            logger.info("TWSNotificationsOverlay: No active window found")
            return
        }

        let controller = UIHostingController(rootView: NotificationView(snippet: snippet, dismiss: { self.dismissOverlay() }))
        controller.view.backgroundColor = .clear
        controller.view.frame = window.bounds
        controller.view.isUserInteractionEnabled = true

        window.addSubview(controller.view)
        window.bringSubviewToFront(controller.view)

        hostingController = controller
    }

    public func dismissOverlay() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
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
