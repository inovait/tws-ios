//
//  SocketTests.swift
//  TWSSnippetsTests
//
//  Created by Miha Hozjan on 12. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import XCTest
@testable import TWSSnippets
@testable import TWSCommon
@testable import ComposableArchitecture

final class SocketTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testConnectingToSocket() async throws {
        let socketURL = URL(string: "https://www.google.com")!
        let stream = AsyncStream<WebSocketEvent>.makeStream()
        let store: TestStoreOf<TWSSnippetsFeature> = .init(
            initialState: TWSSnippetsFeature.State(),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getSnippets = { [] }
                $0.api.getSocket = { socketURL }
                $0.socket.connect = { _ in stream.stream }
            }
        )

        await store.send(.business(.listenForChanges))
        await store.receive(\.business.listenForChangesResponse.success, socketURL)

        // After the socket connection is established, check the snippets again

        stream.continuation.yield(.didConnect)
        await store.receive(\.business.load, timeout: NSEC_PER_SEC)
        await store.receive(\.business.snippetsLoaded.success, [])

        // Stop listening
        await store.send(.business(.stopListeningForChanges))
    }

    @MainActor
    func testReconnectingToSocket() async {
        let socketURL = URL(string: "https://www.google.com")!
        let stream = AsyncStream<WebSocketEvent>.makeStream()
        let clock = TestClock()

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getSnippets = { [] }
                $0.api.getSocket = { socketURL }
                $0.continuousClock = clock
                $0.socket.connect = { _ in stream.stream }
            }
        )

        await store.send(.business(.listenForChanges))
        await store.receive(\.business.listenForChangesResponse.success)

        // After the socket connection is established, check the snippets again

        stream.continuation.yield(.didConnect)
        await store.receive(\.business.load, timeout: NSEC_PER_SEC)
        await store.receive(\.business.snippetsLoaded.success, [])

        // End with didDisconnectEvent
        stream.continuation.yield(.didDisconnect)

        // Reconnect after 1s
        await clock.advance(by: .seconds(1))

        // Ask for new url,...
        await store.receive(\.business.listenForChanges, timeout: NSEC_PER_SEC)
        await store.receive(\.business.listenForChangesResponse.success)

        // After the socket connection is established, check the snippets again

        stream.continuation.yield(.didConnect)
        await store.receive(\.business.load, timeout: NSEC_PER_SEC)
        await store.receive(\.business.snippetsLoaded.success, [])

        // Stop listening
        await store.send(.business(.stopListeningForChanges))
    }
}
