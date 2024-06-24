//
//  NotificationBuilder.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels

class NotificationBuilder {

    static let kSnippetID = "kSnippetID"
    static let kDisplayID = "kDisplayID"

    class func send(
        _ name: Notification.Name,
        snippet: TWSSnippet,
        displayID: String
    ) {
        NotificationCenter.default.post(
            name: name,
            object: nil,
            userInfo: [
                kSnippetID: snippet.id,
                kDisplayID: displayID
            ]
        )
    }

    class func shouldReact(
        to notification: Notification,
        as snippet: TWSSnippet,
        displayID: String
    ) -> Bool {
        guard
            let userInfo = notification.userInfo,
            userInfo[kSnippetID] as? UUID == snippet.id,
            userInfo[kDisplayID] as? String == displayID
        else {
            return false
        }

        return true
    }
}
