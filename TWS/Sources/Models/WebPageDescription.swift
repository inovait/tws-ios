//
//  WebPageDescription.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

struct WebPageDescription: Hashable {

    // periphery:ignore - Used as part of hashable
    let scheme: String?
    // periphery:ignore - Used as part of hashable
    let host: String?
    // periphery:ignore - Used as part of hashable
    let path: String
    // periphery:ignore - Used as part of hashable
    let query: String?

    init(_ target: URL) {
        let path = target.path()

        self.scheme = target.scheme
        self.host = target.host()
        self.path = path == "" ? "/" : path
        self.query = target.query()
    }
}
