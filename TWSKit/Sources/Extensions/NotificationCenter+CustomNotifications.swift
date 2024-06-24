//
//  NotificationCenter+CustomNotifications.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

extension Notification.Name {

    struct Navigation {

        static let Back = Notification.Name(rawValue: "_WebViewGoBack")
        static let Forward = Notification.Name(rawValue: "_WebViewGoForward")
    }
}
