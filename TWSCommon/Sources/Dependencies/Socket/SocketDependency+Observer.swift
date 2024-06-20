//
//  SocketDependency+Observer.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 13. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit

class SocketEventObserver: NSObject, URLSessionWebSocketDelegate {

    let continuation: CheckedContinuation<URLSessionWebSocketTask, Error>
    var isSetup = false
    var socket: URLSessionWebSocketTask?

    init(
        continuation: CheckedContinuation<URLSessionWebSocketTask, Error>
    ) {
        self.continuation = continuation
    }

    // MARK: - Helpers

    func resume(url: URL) {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        let session = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: operationQueue
        )

        socket = session.webSocketTask(with: url)
        socket?.resume()
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        guard !isSetup else { return }
        isSetup = true
        socket = nil
        continuation.resume(returning: webSocketTask)
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        guard !isSetup else { return }
        isSetup = true
        socket = nil
        continuation.resume(throwing: WebSocketError.didClose)
    }
}
