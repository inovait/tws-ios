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

import Testing
import Foundation
import TWSModels

struct CookiesTests {
    
    @Test("parse cookies",
          arguments: [
            """
            {
            "Set-Cookie": [
                "sessionId=abc123; Path=/; HttpOnly; Secure; SameSite=Lax",
                "theme=dark; Path=/; Max-Age=3600",
                "userId=789xyz; Path=/; Expires=Wed, 01 Jan 2025 12:00:00 GMT"
                ]
            }
"""
          ]
    ) func parseHeaders(headers: String) async throws {
        let url = URL(string: "https://example.com")!
        
        let data = headers.data(using: .utf8) ?? Data()
        let parsedData = try #require(
            try JSONSerialization.jsonObject(
                with: data,
                options: []
            ) as? [String : [String]]
        )
        
        var cookies: [HTTPCookie] = []
        let cookieStrings = parsedData["Set-Cookie"]! as [String]
        
        for cookieString in cookieStrings {
            let cookieHeader = ["Set-Cookie": cookieString]
            let parsedCookie = HTTPCookie.cookies(withResponseHeaderFields: cookieHeader, for: url)
            cookies.append(contentsOf: parsedCookie)
        }
        
        var wrappedCookies: [HTTPCookieWrapper] = []
        // Wrap http cookies
        cookies.forEach {
            guard let wrappedCookie = HTTPCookieWrapper(cookie: $0) else { return }
            wrappedCookies.append(wrappedCookie)
        }
        
        var httpCookies: [HTTPCookie] = []
        // Unwrap http cookies
        wrappedCookies.forEach {
            guard let httpCookie = $0.toHTTPCookie() else { return }
            httpCookies.append(httpCookie)
        }
        
        #expect(cookies == httpCookies)
    }
}
