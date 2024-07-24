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
@testable import TWSModels
@testable import ComposableArchitecture

final class SocketTests: XCTestCase {

    let socketURL = URL(string: "https://www.google.com")!
    let configuration = TWSConfiguration(
        organizationID: "00000000-0000-0000-0000-000000000000",
        projectID: "00000000-0000-0000-0000-000000000001"
    )

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testConnectingToSocket() async throws {
        var state = TWSSnippetsFeature.State(configuration: configuration)
        state.socketURL = socketURL

        let clock = TestClock()
        let stream = AsyncStream<WebSocketEvent>.makeStream()
        let store: TestStoreOf<TWSSnippetsFeature> = .init(
            initialState: state,
            reducer: { TWSSnippetsObserverFeature() },
            withDependencies: {
                $0.api.getProject = { _ in TWSProject(listenOn: self.socketURL, snippets: [])}
                $0.socket.get = { _ in .init() }
                $0.socket.connect = { _ in stream.stream }
                $0.socket.closeConnection = { _ in }
                $0.socket.listen = { _ in }
                $0.continuousClock = clock
            }
        )

        await store.send(.business(.listenForChanges))

        // After the socket connection is established, check the snippets again

        stream.continuation.yield(.didConnect)
        await store.receive(\.business.isSocketConnected, true) {
            $0.isSocketConnected = true
        }
        await store.receive(\.business.load, timeout: NSEC_PER_SEC)
        await store.receive(\.business.projectLoaded.success, .init(listenOn: self.socketURL, snippets: []))

        // Stop listening
        await store.send(.business(.stopListeningForChanges))
        await store.receive(\.business.delayReconnect)
        await store.send(.business(.stopReconnecting))
    }

    @MainActor
    func testReconnectingToSocket() async throws {
        var state = TWSSnippetsFeature.State(configuration: configuration)
        state.socketURL = socketURL

        let stream = AsyncStream<WebSocketEvent>.makeStream()
        let clock = TestClock()

        let store = TestStore(
            initialState: state,
            reducer: { TWSSnippetsObserverFeature() },
            withDependencies: {
                $0.api.getProject = { _ in TWSProject(listenOn: self.socketURL, snippets: [])}
                $0.continuousClock = clock
                $0.socket.get = { _ in .init() }
                $0.socket.connect = { _ in stream.stream }
                $0.socket.closeConnection = { _ in }
                $0.socket.listen = { _ in }
            }
        )

        await store.send(.business(.listenForChanges))

        // After the socket connection is established, check the snippets again

        stream.continuation.yield(.didConnect)
        await store.receive(\.business.isSocketConnected, true) {
            $0.isSocketConnected = true
        }
        await store.receive(\.business.load, timeout: NSEC_PER_SEC)
        await store.receive(\.business.projectLoaded.success, .init(listenOn: self.socketURL, snippets: []))

        // End with didDisconnectEvent
        stream.continuation.yield(.didDisconnect)

        await store.receive(\.business.isSocketConnected, false) {
            $0.isSocketConnected = false
        }
        await store.receive(\.business.delayReconnect, timeout: NSEC_PER_SEC)

        // Reconnect after 3s
        await clock.advance(by: .seconds(3))
        await store.receive(\.business.reconnectTriggered, timeout: NSEC_PER_SEC) {
            $0.socketURL = nil
        }

        // Ask for new url,...
        await store.receive(\.business.load)
        await store.receive(\.business.projectLoaded.success, .init(listenOn: self.socketURL, snippets: [])) {
            $0.socketURL = self.socketURL
        }
        await store.receive(\.business.listenForChanges, timeout: NSEC_PER_SEC)

        // After the socket connection is established, check the snippets again

        stream.continuation.yield(.didConnect)
        await store.receive(\.business.isSocketConnected, true) {
            $0.isSocketConnected = true
        }
        await store.receive(\.business.load, timeout: NSEC_PER_SEC)
        await store.receive(\.business.projectLoaded.success, .init(listenOn: self.socketURL, snippets: []))

        // Stop listening
        await store.send(.business(.stopListeningForChanges))
        await store.receive(\.business.delayReconnect)
        await store.send(.business(.stopReconnecting))
    }

    @MainActor
    func testOnSocketMessageRefresh() async throws {
        var state = TWSSnippetsFeature.State(configuration: configuration)
        state.socketURL = socketURL

        let clock = TestClock()
        let socketURL = URL(string: "https://www.google.com")!
        let stream = AsyncStream<WebSocketEvent>.makeStream()
        let store: TestStoreOf<TWSSnippetsFeature> = .init(
            initialState: state,
            reducer: { TWSSnippetsObserverFeature() },
            withDependencies: {
                $0.api.getProject = { _ in TWSProject(listenOn: socketURL, snippets: [])}
                $0.socket.get = { _ in .init() }
                $0.socket.connect = { _ in stream.stream }
                $0.socket.closeConnection = { _ in }
                $0.socket.listen = { _ in }
                $0.continuousClock = clock
            }
        )

        await store.send(.business(.listenForChanges))

        // After the socket connection is established, check the snippets again

        stream.continuation.yield(.didConnect)
        await store.receive(\.business.isSocketConnected, true) {
            $0.isSocketConnected = true
        }
        await store.receive(\.business.load, timeout: NSEC_PER_SEC)
        await store.receive(\.business.projectLoaded.success, .init(listenOn: self.socketURL, snippets: []))

        // After message is received, refresh
        stream.continuation.yield(.receivedMessage(.init(id: .init(), type: .created)))
        await store.receive(\.business.load, timeout: NSEC_PER_SEC)
        await store.receive(\.business.projectLoaded.success, .init(listenOn: self.socketURL, snippets: []))

        // Stop listening
        await store.send(.business(.stopListeningForChanges))
        await store.receive(\.business.delayReconnect)
        await store.send(.business(.stopReconnecting))
    }
}
