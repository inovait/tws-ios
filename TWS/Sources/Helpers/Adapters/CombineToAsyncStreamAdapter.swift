//
//  CombineToAsyncStreamAdapter.swift
//  TWS
//
//  Created by Miha Hozjan on 6. 08. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import Combine

@MainActor
class CombineToAsyncStreamAdapter {

    private let id = UUID().uuidString.suffix(4)
    private var handler: AnyCancellable?
    private var upstream: AnyPublisher<TWSStreamEvent, Never>

    init(
        upstream: AnyPublisher<TWSStreamEvent, Never>
    ) {
        self.upstream = upstream
        logger.info("INIT CombineToAsyncStreamAdapter \(id)")
    }

    deinit {
        logger.info("DEINIT CombineToAsyncStreamAdapter \(id)")
    }

    func listen(
        onEvent: @MainActor @Sendable @escaping (TWSStreamEvent) -> Void
    ) async {
        let stream = AsyncStream<TWSStreamEvent>.makeStream()
        handler = upstream
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    guard let self else { return }
                    cancel(continuation: stream.continuation)
                },
                receiveCancel: { [weak self] in
                    guard let self else { return }
                    cancel(continuation: stream.continuation)
                }
            )
            .sink(receiveValue: { value in
                stream.continuation.yield(value)
            })

        await withTaskCancellationHandler(
            operation: {
                for await event in stream.stream {
                    // Hop the thread
                    await MainActor.run { onEvent(event) }
                }
            },
            onCancel: {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    cancel(continuation: stream.continuation)
                }
            }
        )
    }

    func cancel(
        continuation: AsyncStream<TWSStreamEvent>.Continuation
    ) {
        handler?.cancel()
        handler = nil
        continuation.finish()
    }
}
