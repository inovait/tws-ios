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
        
        guard let urlString = body["url"] as? String,
            let url = URL(string: urlString),
              let navId = body["navId"] as? String,
              let jsonData = try? JSONSerialization.data(withJSONObject: [navId]),
              let jsonArrayString = String(data: jsonData, encoding: .utf8)
        else {
            logger.warn("Could not parse message body navigation request dismissed")
            return
        }
        
        let navIdEsc = String(jsonArrayString.dropFirst().dropLast())
        
        if !interceptor.handleUrl(url) {
            webView.evaluateJavaScript("simulateClick(\(navIdEsc), true)")
        } else {
            webView.evaluateJavaScript("simulateClick(\(navIdEsc), false)")
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
