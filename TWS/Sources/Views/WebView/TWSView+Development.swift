//
//  TWSView+Development.swift
//  TheWebSnippet
//
//  Created by Miha Hozjan on 26. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
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
            var originalLog = console.log;
            function captureLog(msg) {
                originalLog.apply(console, arguments);
                window.webkit.messageHandlers.consoleLogHandler.postMessage(msg);
            }
            console.log = captureLog;
        })();
        """
    }
}
#endif
