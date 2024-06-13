//
//  SocketDependency+Observer.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 13. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit

class SocketEventObserver: NSObject, URLSessionWebSocketDelegate {

    let continuation: AsyncStream<WebSocketEvent>.Continuation

    init(
        continuation: AsyncStream<WebSocketEvent>.Continuation
    ) {
        self.continuation = continuation
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.continuation.yield(.didConnect)
        }
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.continuation.yield(.didDisconnect)
            self?.continuation.finish()
        }
    }
}
