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

import Foundation

actor SocketConnector {

    private let id = UUID().uuidString.suffix(4)
    private let url: URL
    private let continuation: AsyncStream<WebSocketEvent>.Continuation
    private var webSocket: URLSessionWebSocketTask?
    private weak var _observer: SocketEventObserver?

    let stream: AsyncStream<WebSocketEvent>

    init(url: URL) {
        let stream = AsyncStream<WebSocketEvent>.makeStream()
        self.stream = stream.stream
        self.continuation = stream.continuation
        self.url = url
        logger.info("INIT SocketConnector \(id)")
    }

    deinit {
        logger.info("DEINIT SocketConnector \(id)")
    }

    func connect() async throws(SocketMessageReadError) {
        do {
            let socket = try await withCheckedThrowingContinuation { [url] continuation in
                let observer = SocketEventObserver(continuation: continuation)
                observer.start(with: url)
                self._observer = observer
            }

            webSocket = socket
            continuation.yield(.didConnect)
        } catch {
            continuation.yield(.didDisconnect)
            continuation.finish()
            return
        }
    }

    func listen() async throws {
        logger.info("Awaiting a new message from the server")
        guard let webSocket else {
            logger.err("Trying to read from web socket but it is nil")
            throw WebSocketError.webSocketNil
        }

        try await withTaskCancellationHandler(
            operation: { [weak self, webSocket] in
                guard let self else { return }

                let result = try await webSocket.receive()
                switch result {
                case let .data(data):
                    do {
                        try await _processMessage(data: data)
                    } catch let SocketMessageReadError.failedToParse(error) {
                        continuation.yield(.skipUnknownMessage(error))
                    } catch {
                        throw error
                    }

                case let .string(string):
                    logger.info("Received a message from server.")
                    if let data = string.data(using: .utf8) {
                        do {
                            try await _processMessage(data: data)
                        } catch let SocketMessageReadError.failedToParse(error) {
                            continuation.yield(.skipUnknownMessage(error))
                        } catch {
                            throw error
                        }
                    }

                @unknown default:
                    break
                }
            },
            onCancel: {
                continuation.finish()
                Task { [weak self] in
                    logger.info("Canceled listening to websocket")
                    await self?.closeConnection()
                }
            }
        )
    }

    func closeConnection() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        _observer?.invalidate()
    }

    // MARK: - Helper

    private func _processMessage(data: Data) async throws {
        guard
            let jsonData = try JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any],
            let message = SocketMessage(json: jsonData)
        else {
            let rawString = String(data: data, encoding: .utf8) ?? ""
            #if DEBUG
            if
                let jsonData = try JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any],
                let type = jsonData["type"] as? String,
                type == "SNIPPET_CREATED" || type == "SNIPPET_UPDATED" || type == "SNIPPET_DELETED" {
            } else {
                assertionFailure("Failed to process data: \(rawString)")
            }
            #endif

            throw SocketMessageReadError.failedToParse(rawString)
        }

        continuation.yield(.receivedMessage(message))
    }
}
