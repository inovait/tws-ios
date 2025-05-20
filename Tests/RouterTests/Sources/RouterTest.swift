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

import XCTest
import Foundation
import WebKit
@testable import TWSAPI


class RouterTest: XCTestCase {
    
    @MainActor func testRetrieveIntermediateUrls() async throws {
        let cookiesToDelete = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        
        for cookie in cookiesToDelete {
            await WKWebsiteDataStore.default().httpCookieStore.deleteCookie(cookie)
        }
        
        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockURLProtocol.self]
        
        let url = ResultSet.initialUrl
        let urlRequest = URLRequest(url: url)
        
        let url2 = ResultSet.secondUrl
        let concurrentUrlRequest = URLRequest(url: url2)
        
        let delegate = RedirectHandler()
        
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        // Make the request
        Task {
            do {
                let _ = try await session.data(for: concurrentUrlRequest)
            } catch {
                throw error
            }
        }
        
        // Make another request
        do {
            let _ = try await session.data(for: urlRequest)
        } catch {
            throw error
        }
        
        var expectedCookies: [HTTPCookie] = []
        ResultSet.cookieHeaders.enumerated().map { (index, item) in
            expectedCookies.append(contentsOf: HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": item], for: ResultSet.redirects[index]).map{ cookie in
                var propretyDict = cookie.properties
                propretyDict?.updateValue(1, forKey: .version)
                return HTTPCookie(properties: propretyDict!)!
            })
        }
        
        // Collect the result
        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        
        XCTAssert(Set(expectedCookies) == Set(cookies))
        
        
    }
}

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    

    override func startLoading() {
        if let url = request.url {
            if (url == ResultSet.initialUrl) {
                let redirectURL = ResultSet.firstRedirectUrl
                let redirectResponse = HTTPURLResponse(
                    url: url,
                    statusCode: 302,
                    httpVersion: nil,
                    headerFields: ["Set-Cookie": ResultSet.cookieHeaders[0]]
                )!
                
                client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirectURL), redirectResponse: redirectResponse)
            } else if (url == ResultSet.firstRedirectUrl) {
                let redirectURL = ResultSet.secondRedirectUrl
                let redirectResponse = HTTPURLResponse(
                    url: url,
                    statusCode: 302,
                    httpVersion: nil,
                    headerFields: ["Set-Cookie": ResultSet.cookieHeaders[1]]
                )!
                
                client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirectURL), redirectResponse: redirectResponse)
            } else if (url == ResultSet.secondRedirectUrl) {
                let redirectURL = ResultSet.thirdRedirectUrl
                let redirectResponse = HTTPURLResponse(
                    url: url,
                    statusCode: 302,
                    httpVersion: nil,
                    headerFields: ["Set-Cookie": ResultSet.cookieHeaders[2]]
                )!
                
                client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirectURL), redirectResponse: redirectResponse)
            } else if (url == ResultSet.thirdRedirectUrl) {
                let redirectURL = ResultSet.resolvedUrl
                let redirectResponse = HTTPURLResponse(
                    url: url,
                    statusCode: 302,
                    httpVersion: nil,
                    headerFields: ["Set-Cookie": ResultSet.cookieHeaders[3]]
                )!
                
                client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirectURL), redirectResponse: redirectResponse)
            } else if (url == ResultSet.resolvedUrl) {
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: [:]
                )!
                
                let data = "Finished".data(using: .utf8)!
                
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            }
        }
    }

    override func stopLoading() {}
}

struct ResultSet {
    static let initialUrl = URL(string: "https://www.example.com")!
    static let secondUrl = URL(string: "https://www.example.com")!
    
    static let firstRedirectUrl = URL(string: "https://www.firstredirect.com")!
    static let secondRedirectUrl = URL(string: "https://www.secondredirect.com")!
    static let thirdRedirectUrl = URL(string: "https://www.thirdredirect.com")!
    static let resolvedUrl = URL(string: "https://www.resolvedUrl.com")!
    
    static let redirects: [URL] = [
        initialUrl,
        firstRedirectUrl,
        secondRedirectUrl,
        thirdRedirectUrl
    ]
    
    static let cookieHeaders = [
        "sessionId=abc123; Path=/; HttpOnly; Expires=Fri, 31 Dec 9999 23:59:59 GMT",
        "sessionId=def456; Path=/; HttpOnly; Expires=Fri, 31 Dec 9999 23:59:59 GMT",
        "sessionId=ghi789; Path=/; HttpOnly; Expires=Fri, 31 Dec 9999 23:59:59 GMT",
        "sessionId=finished; Path=/; HttpOnly; Expires=Fri, 31 Dec 9999 23:59:59 GMT"]
}
