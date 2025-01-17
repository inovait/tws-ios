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
