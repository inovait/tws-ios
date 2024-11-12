//
//  ConsoleMessageHandler.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import WebKit

#if DEBUG
class ConsoleLogMessageHandler: NSObject, WKScriptMessageHandler {

    @MainActor
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if message.name == "consoleLogHandler" {
            logger.debug("[Console]: \(message.body)")
        }
    }
}
#endif
