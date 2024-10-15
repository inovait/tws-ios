//
//  SocketDependency+Observer.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 13. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit

actor SocketEventObserver: NSObject, URLSessionWebSocketDelegate {

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

    nonisolated func start(with url: URL) {
        Task { await _start(with: url) }
    }

    nonisolated func invalidate() {
        Task { await _invalidate() }
    }

    // MARK: - URLSessionWebSocketDelegate

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Task { await _continue(
            withWebSocketTask: webSocketTask,
            result: .success(webSocketTask)
        )}
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        Task { await _continue(
            withWebSocketTask: webSocketTask,
            result: .failure(WebSocketError.didClose)
        )}
    }

    // MARK: - Helpers

    private func _start(
        with url: URL
    ) {
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

    private func _continue(
        withWebSocketTask webSocketTask: URLSessionWebSocketTask,
        result: Result<URLSessionWebSocketTask, Error>
    ) {
        guard !isSetup else { return }
        isSetup = true
        assert(socket === webSocketTask)
        socket = nil
        continuation?.resume(with: result)
        continuation = nil
    }

    private func _invalidate() {
        session?.invalidateAndCancel()
    }
}
