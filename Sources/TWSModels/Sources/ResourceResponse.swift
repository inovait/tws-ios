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

public struct ResourceResponse: Sendable, Equatable, Codable, Hashable {
    public let responseUrl: URL?
    public var cookies: [HTTPCookieWrapper]
    public let data: String
    
    public init(responseUrl: URL?, cookies: [HTTPCookieWrapper], data: String) {
        self.responseUrl = responseUrl
        self.cookies = cookies
        self.data = data
    }
    
    enum CodingKeys: String, CodingKey {
        case responseUrl, data, cookies
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(responseUrl, forKey: .responseUrl)
        try container.encode(data, forKey: .data)
        try container.encode(cookies, forKey: .cookies)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(String.self, forKey: .data)
        self.responseUrl = try container.decodeIfPresent(URL.self, forKey: .responseUrl)
        self.cookies = try container.decode([HTTPCookieWrapper].self, forKey: .cookies)
    }

}

public struct HTTPCookieWrapper: Codable, Equatable, Hashable, Sendable {
    
    let properties: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case properties
    }
    
    public func toHTTPCookie() -> HTTPCookie? {
        var props: [HTTPCookiePropertyKey: Any] = [:]

        for (key, value) in properties {
            let propertyKey = HTTPCookiePropertyKey(key)
            
            if propertyKey == .expires {
                if let date = ISO8601DateFormatter().date(from: value) {
                    props[propertyKey] = date
                    continue
                }
            }

            props[propertyKey] = value
        }

        return HTTPCookie(properties: props)
    }
    
    public init?(cookie: HTTPCookie) {
        guard let props = cookie.properties else { return nil }

        var stringProps: [String: String] = [:]
        for (key, value) in props {
            if let stringValue = value as? String {
                stringProps[key.rawValue] = stringValue
            } else if let dateValue = value as? Date {
                stringProps[key.rawValue] = ISO8601DateFormatter().string(from: dateValue)
            } else if let numberValue = value as? NSNumber {
                stringProps[key.rawValue] = numberValue.stringValue
            }
        }

        self.properties = stringProps
    }
}
