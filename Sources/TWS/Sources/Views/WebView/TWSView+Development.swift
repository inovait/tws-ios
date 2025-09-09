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

import WebKit
import TWSModels

#if DEBUG
extension WebView {

    func interceptConsoleLogs(
        controller: WKUserContentController
    ) -> TWSRawJS {
        controller.add(ConsoleLogMessageHandler(), name: "consoleLogHandler")

        return """
        (function() {
            const consoleMethods = ['log', 'warn', 'error', 'info', 'debug', 'trace'];

            consoleMethods.forEach(method => {
                const original = console[method];

                console[method] = function(...args) {
                    original.apply(console, args);

                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLogHandler) {
                        try {
                            window.webkit.messageHandlers.consoleLogHandler.postMessage({
                                type: method,
                                message: args.map(arg => {
                                    try {
                                        return typeof arg === 'object' ? JSON.stringify(arg) : String(arg);
                                    } catch {
                                        return String(arg);
                                    }
                                }).join(' ')
                            });
                        } catch (e) {
                            
                        }
                    }
                };
            });
        })();
        """
    }
}
#endif
