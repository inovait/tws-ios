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
import TWS

enum NotificationType: String {
    case snippet_push = "snippet_push"
}

@MainActor
public final class TWSNotification {
    private var listenerTask: Task<Void, Never>? = nil
    
    public init() {}
    
    // MARK: Public
    
    /// Tries to handle notification data in a way that displays a full screen overlay of TWSView, displaying a snippet parsed from push notification body.
    /// Note: Manager instance for the configuration this notification is trying to access should be created and alive before you try calling this method.
    /// Meaning if you are handling notifications with UIApplicationDelegate, you should create and register manager before you apply the @UIApplicationDelegateAdaptor.
    /// # Example
    ///
    /// ```swift
    /// @main
    /// struct SampleApp: App {
    ///     let manager = TWSFactory.new(with: TWSBasicConfiguration(id: "<PROJECT_ID>))
    ///     @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .twsEnable(using: manager)
    ///         }
    ///      }
    ///   }
    /// ```
    ///
    /// - Parameter userInfo: Dictionary of values recieved from remote notification.
    ///
    /// - Returns true if the parsing of `NotificationType` and `NotificationData` succeeds, in this case notification can be considered processed, however if the provided project or snippet does not exists it will do nothing. If body can not be parsed it returns false.
    ///
    /// # Example
    ///
    /// ```swift
    /// func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    ///     if TWSNotification().handleTWSPushNotification(userInfo) {
    ///         //Can be considered handled and return
    ///         return
    ///     }
    ///
    ///     ...the rest of notification handling logic
    /// }
    /// ```
    ///
    public func handleTWSPushNotification(_ userInfo: [AnyHashable : Any]) -> Bool {
        guard
            let type = userInfo["type"] as? String,
            type == NotificationType.snippet_push.rawValue,
            let path = userInfo["path"] as? String else { return false }

        let notificationData = parsePath(path)
        let manager = TWSFactory.get(with: TWSBasicConfiguration(id: notificationData.projectId))
        
        guard let manager else {
            logger.warn("Can not open overlay for snippet \(notificationData.snippetId), because TWSManager does not exist for the configuration with id \(notificationData.projectId)")
            return false
        }
        
        self.listenerTask = Task {
            await manager.observe(onEvent: {
                switch $0 {
                case .stateChanged:
                    if case .failed(_) = manager.snippets.state {
                        self.listenerTask?.cancel()
                    }
                    if manager.snippets.state == .loaded {
                        if let desiredSnippet = manager.snippets().first(where: { snippet in snippet.id == notificationData.snippetId }) {
                            TWSOverlayProvider.shared.showOverlay(snippet: desiredSnippet, manager: manager)
                            self.listenerTask?.cancel()
                            return
                        }
                    }
                default:
                    break
                }
            })
        }
        
        return true
    }
    
    // MARK: Private
    
    private func parsePath(_ path: String) -> NotificationData {
        let ids = path.split(separator: "/")
        let projectId = String(ids[0])
        let snippetId = String(ids[1])
        
        return NotificationData(projectId: projectId, snippetId: snippetId)
    }
    
    struct NotificationData {
        var projectId: String
        var snippetId: String
    }
}
