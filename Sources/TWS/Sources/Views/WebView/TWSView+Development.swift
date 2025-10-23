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
          var handler = window.webkit?.messageHandlers?.consoleLogHandler;
          if (!handler) return; // Safely exit if handler is not available

          var original = {
            log: console.log,
            warn: console.warn,
            error: console.error,
            info: console.info,
            debug: console.debug
          };

          function sendToHandler(level, args) {
            try {
              const message = {
                level: level,
                args: Array.from(args).map(a => {
                  try {
                    return typeof a === 'object' ? JSON.stringify(a) : String(a);
                  } catch {
                    return String(a);
                  }
                })
              };
              handler.postMessage(message);
            } catch (err) {
              original.error('Failed to send console message:', err);
            }
          }

          console.log = function() {
            original.log.apply(console, arguments);
            sendToHandler('log', arguments);
          };

          console.warn = function() {
            original.warn.apply(console, arguments);
            sendToHandler('warn', arguments);
          };

          console.error = function() {
            original.error.apply(console, arguments);
            sendToHandler('error', arguments);
          };

          console.info = function() {
            original.info.apply(console, arguments);
            sendToHandler('info', arguments);
          };

          console.debug = function() {
            original.debug.apply(console, arguments);
            sendToHandler('debug', arguments);
          };
        })();
        """
    }
}
#endif
