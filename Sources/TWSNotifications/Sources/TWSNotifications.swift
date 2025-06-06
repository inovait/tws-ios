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
import TWSModels

enum NotificationType: String {
    case snippet_push = "snippet_push"
}

@MainActor
public final class TWSNotification {
    private var listenerTask: Task<Void, Never>? = nil
    
    public init() {}
    
    // MARK: Public
    
    public func handleTWSPushNotification(_ userInfo: [AnyHashable : Any]) -> Bool {
        guard
            let type = userInfo["type"] as? String,
            type == NotificationType.snippet_push.rawValue,
            let path = userInfo["path"] as? String else { return false }

        let notificationData = parsePath(path)
        let manager = TWSFactory.new(with: TWSBasicConfiguration(id: notificationData.projectId))
        
        self.listenerTask = Task {
            await manager.observe(onEvent: {
                switch $0 {
                case .snippetsUpdated:
                    if let desiredSnippet = manager.snippets().first(where: { snippet in snippet.id == notificationData.snippetId }) {
                        TWSNotificationsOverlay.shared.showOverlay(snippet: desiredSnippet)
                        self.listenerTask?.cancel()
                    }
                case .stateChanged:
                    if case .failed(_) = manager.snippets.state {
                        self.listenerTask?.cancel()
                    }
                    if manager.snippets.state == .loaded {
                        self.listenerTask?.cancel()
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
