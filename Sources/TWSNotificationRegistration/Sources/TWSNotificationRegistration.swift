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

@MainActor
public class TWSNotificationRegistrationData {
    private static let shared: TWSNotificationRegistrationData = TWSNotificationRegistrationData()
    
    private var deviceToken: String? {
        didSet {
            NotificationCenter.default.post(name: .deviceTokenChangedNotification, object: deviceToken)
        }
    }
    
    public static let deviceTokenStream = AsyncStream<String> { continuation in
        let observer = NotificationCenter.default.addObserver(
            forName: .deviceTokenChangedNotification,
            object: nil,
            queue: nil
        ) { notification in
            if let token = notification.object as? String {
                continuation.yield(token)
            }
            
        }
    }
    
    private init() {}
    
    public static func registerDeviceToken(fcmDeviceToken: String?) {
        shared.deviceToken = fcmDeviceToken
    }
    
    public static func getDeviceToken() -> String? {
        return shared.deviceToken
    }
}

extension Notification.Name {
    static let deviceTokenChangedNotification = Notification.Name("DeviceTokenChangedNotification")
}
