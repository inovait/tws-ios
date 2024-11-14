//
//  TWSSnippetsFeature-Helpers.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 11. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import ComposableArchitecture
import TWSCommon
import Foundation
@_spi(Internals) import TWSModels

extension TWSSnippetsFeature {

    func sort(basedOn orderedIDs: [TWSSnippet.ID], _ state: inout State) {
        var orderDict = [TWSSnippet.ID: Int]()
        for (index, id) in orderedIDs.enumerated() {
            orderDict[id] = index
        }

        state.snippets.sort(by: {
            let idx1 = orderDict[$0.id] ?? Int.max
            let idx2 = orderDict[$1.id] ?? Int.max
            return idx1 < idx2
        })
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
                                        action: .business(.snippetUpdated(snippet: snippet))
                                    )
                                )
                            )
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
            }
        }
    }
}
