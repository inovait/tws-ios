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
import WebKit

class InterceptorBridge: NSObject, WKScriptMessageHandler {
    let interceptor: any TWSViewInterceptor
    let webView: WKWebView
    
    init(interceptor: any TWSViewInterceptor, webView: WKWebView) {
        self.interceptor = interceptor
        self.webView = webView
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "shouldIntercept",
              let body = message.body as? [String: Any] else {
            return
        }
        
        guard let methodString = body["method"] as? String,
              let type = body["type"] as? String,
              let path = body["url"] as? String,
              let navId = body["navId"] as? String,
              let method = MethodType(rawValue: methodString)
        else {
            logger.debug("Invalid body format: \(body)")
            return
        }
        
        guard let webViewUrl = webView.url,
        let baseUrl = getBaseURL(url: webViewUrl) else {
            logger.debug("Could not get base URL")
            return
        }
        
        let url = baseUrl.appendingPathComponent(path)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: [navId]),
           let jsonString = String(data: jsonData, encoding: .utf8) else
        {
            return
        }
        
        let escapedNavId = jsonString.dropFirst().dropLast()
        
        if !interceptor.handleUrl(url) {
                switch method {
                case .click:
                    webView.load(URLRequest(url: url))
                case .pushState:
                    webView.evaluateJavaScript("window.__proceedWithNavigation(\(escapedNavId))")
                }
        }
        
    }
    
    private func getBaseURL(url: URL) -> URL? {
        var baseUrl = URLComponents()
        baseUrl.scheme = url.scheme
        baseUrl.host = url.host
        baseUrl.port = url.port
        
        return baseUrl.url
    }
}


enum MethodType: String, Identifiable {
    var id: String { rawValue }

    case click
    case pushState
}
