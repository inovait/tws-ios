//
//  SocketDependncy+Implementation.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 13. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

class SocketConnector {

    private let url: URL
    private let continuation: AsyncStream<WebSocketEvent>.Continuation
    private var webSocket: URLSessionWebSocketTask?
    private var listeningTask: Task<Void, Never>?

    let stream: AsyncStream<WebSocketEvent>

    init(url: URL) {
        logger.info("INIT SocketConnector")
        let stream = AsyncStream<WebSocketEvent>.makeStream()
        self.stream = stream.stream
        self.continuation = stream.continuation
        self.url = url
    }

    deinit {
        logger.info("DEINIT SocketConnector")
    }

    func connect() async throws {
        do {
            try await withCheckedThrowingContinuation { [weak self, url] continuation in
                let observer = SocketEventObserver(continuation: continuation)
                let operationQueue = OperationQueue()
                operationQueue.maxConcurrentOperationCount = 1

                let session = URLSession(
                    configuration: .default,
                    delegate: observer,
                    delegateQueue: operationQueue
                )

                self?.webSocket = session.webSocketTask(with: url)
                self?.webSocket?.resume()
            }

            continuation.yield(.didConnect)
        } catch {
            continuation.yield(.didDisconnect)
            continuation.finish()
            return
        }
    }

    func listen() async throws {
        logger.info("Will start listening")
        guard let webSocket else {
            throw WebSocketError.webSocketNil
        }

        let result = try await webSocket.receive()
        switch result {
        case let .data(data):
            try await _processMessage(data: data)

        case let .string(string):
            logger.info("Received a message: \(string)")
            if let data = string.data(using: .utf8) {
                try await _processMessage(data: data)
            }

        @unknown default:
            break
        }
    }

    func closeConnection() {
        print("-> websocket is set to nil")
        webSocket?.cancel()
        webSocket = nil
    }

    // MARK: - Helper

    private func _processMessage(data: Data) async throws {
        guard
            let jsonData = try JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any],
            let message = SocketMessage(json: jsonData)
        else {
            let rawString = String(decoding: data, as: UTF8.self)
            assertionFailure("Failed to process data: \(rawString)")
            throw SocketMessageReadError.failedToParse(rawString)
        }

        continuation.yield(.receivedMessage(message))
    }
}
