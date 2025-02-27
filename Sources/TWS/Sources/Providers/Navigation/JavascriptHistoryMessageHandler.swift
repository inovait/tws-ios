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

class JavaScriptHistoryMessageHandler: NSObject, WKScriptMessageHandler {
    private let adapter: JavaScriptHistoryAdapter

    init(adapter: JavaScriptHistoryAdapter) {
        self.adapter = adapter
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "historyObserver" {
            guard
                let payload = message.body as? String,
                let data = payload.data(using: .utf8),
                let message = try? JSONDecoder().decode(JSHistoryMessage.self, from: data)
            else {
                assertionFailure("Failed to decode a message")
                return
            }
            guard let url = URL(string: message.url) else { return }
            Task { await adapter.coordinator?.pushState(url: url) }
        }
    }
}

actor JavaScriptHistoryAdapter {
    var coordinator: WebView.Coordinator?
    
    func bind(coordinator: WebView.Coordinator) {
        self.coordinator = coordinator
    }
}

fileprivate struct JSHistoryMessage: Decodable {
    var url: String
    var type: String
}
