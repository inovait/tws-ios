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
import ComposableArchitecture
import TWSCommon
import Foundation
import TWSSnippet
@_spi(Internals) import TWSModels

extension TWSSnippetsFeature {

    func sort(basedOn orderedIDs: [TWSSnippet.ID], _ state: inout State) {
        var orderDict = [TWSSnippet.ID: Int]()
        for (index, id) in orderedIDs.enumerated() {
            orderDict[id] = index
        }

        func _algo(lhs: TWSSnippetFeature.State, rhs: TWSSnippetFeature.State) -> Bool {
            let idx1 = orderDict[lhs.id] ?? Int.max
            let idx2 = orderDict[rhs.id] ?? Int.max
            return idx1 < idx2
        }

        #if TESTING
        // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
        state.snippets.sort(by: _algo)
        #else
        state.$snippets.withLock { $0.sort(by: _algo)}
        #endif
    }

    func listen(
        connectionID: UUID,
        stream: AsyncStream<WebSocketEvent>,
        send: Send<TWSSnippetsFeature.Action>
    ) async throws {
        mainLoop: for await event in stream {
            switch event {
            case .didConnect:
                logger.info("Did connect \(Date.now)")
                await send(.business(.isSocketConnected(true)))
                await send(.business(.load))

                do {
                    try await socket.listen(connectionID)
                } catch {
                    logger.err("Failed to receive a message: \(error)")
                    break mainLoop
                }

                if Task.isCancelled { break mainLoop }

            case .didDisconnect:
                logger.info("Did disconnect \(Date())")
                await send(.business(.isSocketConnected(false)))
                break mainLoop

            case let .receivedMessage(message):
                logger.info("Received a message: \(message)")

                switch message.type {
                case .created, .deleted:
                    await send(.business(.load))

                case .updated:
                    if let snippet = message.snippet {
                        await send(
                            .business(
                                .snippets(
                                    .element(
                                        id: message.id,
                                        action: .business(.snippetUpdated(
                                            snippet: snippet
                                        ))
                                    )
                                )
                            )
                        )
                        
                        await send(
                            .business(.updateCampaign(snippet))
                        )

                        await send(.business(.startVisibilityTimers([snippet])))
                    }
                }

                do {
                    try await socket.listen(connectionID)
                } catch {
                    logger.err("Failed to receive a message: \(error)")
                    break mainLoop
                }

            case let .skipUnknownMessage(error):
                logger.warn("Skipped processing the message due to a parsing failure: \(error)")
                do {
                    try await socket.listen(connectionID)
                } catch {
                    logger.err("Failed to receive a message: \(error)")
                    break mainLoop
                }
            }
        }
    }
}
