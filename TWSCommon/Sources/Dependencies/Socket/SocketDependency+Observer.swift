//
//  SocketDependency+Observer.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 13. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit

class SocketEventObserver: NSObject, URLSessionWebSocketDelegate {

    let continuation: CheckedContinuation<Void, Error>
    var isSetup = false

    init(
        continuation: CheckedContinuation<Void, Error>
    ) {
        self.continuation = continuation
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        guard !isSetup else { return }
        isSetup = true
        continuation.resume()
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        guard !isSetup else { return }
        isSetup = true
        continuation.resume(throwing: WebSocketError.didClose)
    }
}
