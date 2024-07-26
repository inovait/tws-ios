//
//  Request.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

struct Request {

    let method: Method
    let path: String
    let host: String
    let queryItems: [URLQueryItem]
    let headers: [String: String]
}

extension Request {

    enum Method: String {
        case get
        case post
    }
}
