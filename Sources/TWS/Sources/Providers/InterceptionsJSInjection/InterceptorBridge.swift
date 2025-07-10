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
    let interceptor: (any TWSViewInterceptor)?
    let webView: WKWebView
    
    init(interceptor: (any TWSViewInterceptor)?, webView: WKWebView) {
        self.interceptor = interceptor
        self.webView = webView
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "shouldIntercept",
              let body = message.body as? [String: Any] else {
            return
        }
            
        guard let payload = body["payload"] else {
            logger.warn("No payload present in message body")
            return
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            logger.warn("Failed to parse payload")
            return
        }
        
        guard let interceptor else {
            logger.info("No interceptor provided")
            webView.evaluateJavaScript("pushStateContinuation(false, \(jsonString))")
            return
        }
        
        let urlString = (body["url"] as? String) ?? "about:blank"
        guard let url = URL(string: urlString) else {
            logger.warn("Could not parse url")
            webView.evaluateJavaScript("pushStateContinuation(false, \(jsonString))")
            return
        }
        
        // call js with either with the result
        webView.evaluateJavaScript("pushStateContinuation(\(interceptor.handleUrl(url)), \(jsonString))")
            
    }
}
