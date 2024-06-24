//
//  WebPageDescription.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

struct WebPageDescription: Hashable {

    let scheme: String?
    let host: String?
    let path: String
    let query: String?

    init(_ target: URL) {
        let path = target.path()

        self.scheme = target.scheme
        self.host = target.host()
        self.path = path == "" ? "/" : path
        self.query = target.query()
    }
}
