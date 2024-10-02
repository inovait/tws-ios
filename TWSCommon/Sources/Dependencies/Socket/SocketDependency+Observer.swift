//
//  SocketDependency+Observer.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 13. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit

class SocketEventObserver: NSObject, URLSessionWebSocketDelegate {

    private let id = UUID().uuidString.suffix(4)
    private var continuation: CheckedContinuation<URLSessionWebSocketTask, Error>?
    private var isSetup = false
    private var socket: URLSessionWebSocketTask?
    private weak var session: URLSession?

    init(
        continuation: CheckedContinuation<URLSessionWebSocketTask, Error>
    ) {
        self.continuation = continuation
        logger.info("INIT SocketEventObserver \(id)")
    }

    deinit {
        print("DEINIT SocketEventObserver \(id)")
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
        self.session = session

        socket = session.webSocketTask(with: url)
        socket?.resume()
    }

    func invalidate() {
        session?.invalidateAndCancel()
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        guard !isSetup else { return }
        isSetup = true
        assert(socket === webSocketTask)
        socket = nil
        continuation?.resume(returning: webSocketTask)
        continuation = nil
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        guard !isSetup else { return }
        isSetup = true
        assert(socket === webSocketTask)
        socket = nil
        continuation?.resume(throwing: WebSocketError.didClose)
        continuation = nil
    }
}
