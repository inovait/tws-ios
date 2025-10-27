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
import NotificationCenter

struct LocalNotificationProvider {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func sendNotification() async -> PermissionStatus {
        let uuid = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuid, content: createNotification(), trigger: nil)
        
        let settings = await notificationCenter.notificationSettings()
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Notification could not be shown: \(error.localizedDescription)")
        }
        
        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            return .allowed
        case .denied:
            return .notAllowed
        case .notDetermined:
            do {
                if try await isPermissionGranted() {
                    return await sendNotification()
                }
            } catch {
                print("Could not check permission: \(error.localizedDescription)")
            }
        @unknown default:
            break
        }
        
        return .notAllowed
    }
    
    private func isPermissionGranted() async throws -> Bool {
        do {
            let isPermissionGranted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            return isPermissionGranted
        } catch {
            throw error
        }
    }
    
    private func createNotification() -> UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        notification.title = String(localized: "notification.title")
        notification.body = String(localized: "notification.body")
        
        notification.userInfo.updateValue("snippet_push", forKey: "type")
        notification.userInfo.updateValue("example/notificationExample", forKey: "path")
        
        notification.sound = .default
        
        return notification
    }
    
    enum PermissionStatus {
        case allowed, notAllowed
    }
}
