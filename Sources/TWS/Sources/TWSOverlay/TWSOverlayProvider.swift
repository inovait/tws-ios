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

@MainActor
public class TWSOverlayProvider: NSObject, UISceneDelegate {
    private var hostingControllers: [String : UIHostingController<TWSOverlayView>] = [:]

    public static let shared = TWSOverlayProvider()
    private var queuedSnippets: [TWSOverlayData] = []

    private override init() {
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tryPresentingOverlay),
            name: UIScene.didActivateNotification,
            object: nil)
    }

    // MARK: Public
    
    ///
    /// Tries so display provided snippet as a full screen overlay over current window. If window does not yet exist it is queued and displayed when the application notifies that UIScene has appeared.
    /// - Parameter snippet: An instance of TWSSnippet that will be displayed
    ///
    public func showOverlay(snippet: TWSSnippet, manager: TWSManager, type: TWSOverlayType) {
        queuedSnippets.append(.init(snippet: snippet, manager: manager, type: type))
        tryPresentingOverlay()
    }
    
    // MARK: Private
    
    @objc private func tryPresentingOverlay() {
        guard let window = getWindowScene() else {
            logger.info("TWSNotificationsOverlay: No active window found")
            return
        }
        
        while let queuedItem = queuedSnippets.first {
            let snippet = queuedItem.snippet
            let id = "\(snippet.id)-\(UUID())"
            var controller: UIHostingController<TWSOverlayView>!
            let notificationView = TWSOverlayView(id: id, overlayData: queuedItem, dismiss: { viewId in
                self.removeHostingController(viewId)
            })
            controller = UIHostingController(rootView: notificationView)
            controller.view.backgroundColor = .clear
            controller.view.frame = window.bounds
            controller.view.isUserInteractionEnabled = true
            
            window.addSubview(controller.view)
            window.bringSubviewToFront(controller.view)
            hostingControllers.updateValue(controller, forKey: id)
            
            queuedSnippets.remove(at: 0)
        }
    }
    
    private func removeHostingController(_ viewId: String) {
        guard let controller = hostingControllers[viewId] else { return }
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()

        hostingControllers.removeValue(forKey: viewId)
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

struct TWSOverlayData {
    let snippet: TWSSnippet
    let manager: TWSManager
    let type: TWSOverlayType
}

public enum TWSOverlayType {
    case notification, campaign
}
