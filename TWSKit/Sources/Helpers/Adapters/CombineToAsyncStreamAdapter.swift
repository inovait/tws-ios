//
//  CombineToAsyncStreamAdapter.swift
//  TWSKit
//
//  Created by Miha Hozjan on 6. 08. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import Combine

@MainActor
class CombineToAsyncStreamAdapter {

    private var handler: AnyCancellable?
    private var upstream: AnyPublisher<TWSStreamEvent, Never>

    init(
        upstream: AnyPublisher<TWSStreamEvent, Never>
    ) {
        self.upstream = upstream
    }

    func listen(
        onEvent: @MainActor @Sendable @escaping (TWSStreamEvent) -> Void
    ) async {
        let stream = AsyncStream<TWSStreamEvent>.makeStream()
        handler = upstream
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    guard let self else { return }
                    cancel()
                    stream.continuation.finish()
                },
                receiveCancel: { [weak self] in
                    guard let self else { return }
                    cancel()
                    stream.continuation.finish()
                }
            )
            .sink(receiveValue: { value in
                stream.continuation.yield(value)
            })

        await withTaskCancellationHandler(
            operation: {
                for await event in stream.stream {
                    // Hop the thread
                    DispatchQueue.main.async { onEvent(event) }
                }
            },
            onCancel: {
                Task { [weak self] in
                    guard let self else { return }
                    await cancel()
                }
            }
        )
    }

    func cancel() {
        handler?.cancel()
        handler = nil
    }
}
