//
//  SocketDependncy+Implementation.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 13. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

class SocketConnector {

    private let observer: SocketEventObserver
    private let url: URL
    private var webSocket: URLSessionWebSocketTask?
    private var listeningTask: Task<Void, Never>?

    let stream: AsyncStream<WebSocketEvent>

    init(url: URL) {
        print("-> INIT SocketConnector")
        let stream = AsyncStream<WebSocketEvent>.makeStream()
        self.observer = .init(continuation: stream.continuation)
        self.stream = stream.stream
        self.url = url
    }

    deinit {
        print("-> DEINIT SocketConnector")
    }

    func connect() {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        let session = URLSession(configuration: .default, delegate: observer, delegateQueue: operationQueue)
        webSocket = session.webSocketTask(with: url)
        print("-> websocket is set")
        webSocket?.resume()
    }

    func listen() async throws {
        assert(Thread.isMainThread)
        print("-> listen start")
        guard let webSocket else {
            fatalError() // TODO:
        }

        let result = try await webSocket.receive()
        switch result {
        case let .data(data):
            print("-> received data \(data.count)")

        case let .string(string):
            print("-> received string \(string)")

        @unknown default:
            print("...") // TODO:
        }
    }

    func closeConnection() {
        print("-> websocket is set to nil")
        webSocket?.cancel()
        webSocket = nil
    }
}
