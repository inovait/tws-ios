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
        (function () {
            const handler = window.webkit?.messageHandlers?.consoleLogHandler;

            if (!handler) return;

            const methods = ["log", "warn", "info", "error", "debug"];

            const safeStringify = (value) => {
                try { return JSON.stringify(value); }
                catch { return String(value); }
            };

            const send = (type, args) => {
                try {
                    handler.postMessage({
                        type,
                        timestamp: Date.now(),
                        args: Array.from(args).map(safeStringify)
                    });
                } catch (_) {
                }
            };

            methods.forEach((method) => {
                const original = console[method];

                console[method] = function (...args) {
                    send(method, args);
                    original.apply(console, args);
                };
            });
        })();
        """
    }
}
#endif
