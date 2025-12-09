//
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

struct Request {
    let method: Method
    let scheme: String
    let path: String
    let host: String
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let auth: Bool
    var body: [String: Any]
    let url: URL?
    
    init(
        method: Method,
        scheme: String,
        path: String,
        host: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        auth: Bool = false,
        body: [String: Any] = [:]
    ) {
        self.method = method
        self.scheme = scheme
        self.path = path
        self.host = host
        self.queryItems = queryItems
        self.headers = headers
        self.auth = auth
        self.body = body
        self.url = nil
    }
    
    init(
        method: Method,
        url: URL,
        headers: [String: String] = [:],
        auth: Bool = false,
        body: [String: Any] = [:]
    ) {
        self.method = method
        self.scheme = url.scheme ?? "https"
        self.path = url.path
        self.host = url.host ?? ""
        
        self.headers = headers
        self.auth = auth
        self.body = body
        self.queryItems = []
        self.url = url
    }
}


extension Request {

    enum Method: String {
        case get
        case post
    }
}
