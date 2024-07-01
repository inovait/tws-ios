//
//  URL+Authentication.swift
//  TWSCommon
//
//  Created by Miha Hozjan on 1. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public extension URL {

    func isTWSAuthenticationRequest() -> Bool {
        let endpoints = [
            "https://accounts.google.com"
        ]

        for endpoint in endpoints {
            if absoluteString.starts(with: endpoint) { return true }
        }

        return false
    }
}
