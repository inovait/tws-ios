//
//  ttt.swift
//  TWSDemoTests
//
//  Created by Miha Hozjan on 29. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import XCTest
@testable import TWSSnippets
@testable import TWSSnippet
@testable import TWSCommon
@testable import TWSModels
@testable import ComposableArchitecture

final class SnippetsTests: XCTestCase {

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
    func testAPIShouldNotOverrideState() async {
        let s1ID = "1"
        let s2ID = "2"
        let s3ID = "3"

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!)
        ]

        let state = TWSSnippetsFeature.State(configuration: configuration)

        let store = TestStore(
            initialState: state,
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in (TWSProject(listenOn: socketURL, snippets: snippets), nil)}
                $0.api.getResource = { _, _ in return "" }
                $0.date.now = Date()
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
            $0.socketURL = self.socketURL
        }
        await store.receive(\.business.startVisibilityTimers)

        await store.send(
            .business(.snippets(.element(id: s1ID, action: .business(.update(height: 500, forId: "display1")))))
        ) {
            $0.snippets[id: s1ID]?.displayInfo.displays["display1"] = .init(id: "display1", height: 500)
        }

        // Send response for the second time (state must be preserved)
        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success)
        await store.receive(\.business.startVisibilityTimers)
    }

    @MainActor
    func testAPIShouldRemoveFromStateOnceNotReturned() async {
        let s1ID = "1"
        let s2ID = "2"
        let s3ID = "3"

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!)
        ]

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in (TWSProject(listenOn: socketURL, snippets: snippets), nil)}
                $0.api.getResource = { _, _ in return "" }
                $0.date.now = Date()
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
            $0.socketURL = self.socketURL
        }
        await store.receive(\.business.startVisibilityTimers)

        // Send for the second time without one element. Snippet should be removed from state

        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: [snippets[1], snippets[2]]), nil)
        }

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets.removeFirst()
        }
        await store.receive(\.business.startVisibilityTimers)
    }

    @MainActor
    func testAPIShouldAddNewWhenReturned() async {
        let s1ID = "1"
        let s2ID = "2"
        let s3ID = "3"

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!)
        ]

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in
                    (TWSProject(listenOn: socketURL, snippets: [snippets[0], snippets[2]]), nil)
                }
                $0.api.getResource = { _, _ in return "" }
                $0.date.now = Date()
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippets[0], snippets[2]].map { .init(snippet: $0) })
            $0.socketURL = self.socketURL
        }
        await store.receive(\.business.startVisibilityTimers)

        // Send for the second time with new element. Snippet should be added in right order
        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: snippets), nil)
        }

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets.insert(.init(snippet: snippets[1]), at: 1)
        }
        await store.receive(\.business.startVisibilityTimers)
    }

    @MainActor
    func testAPIOrderChange() async {
        let s1ID = "1"
        let s2ID = "2"
        let s3ID = "3"

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!)
        ]

        let snippetsStates: [TWSSnippetFeature.State] = snippets.map { .init(snippet: $0) }

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in (TWSProject(listenOn: socketURL, snippets: snippets), nil)}
                $0.api.getResource = { _, _ in return "" }
                $0.date.now = Date()
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: snippetsStates)
            $0.socketURL = self.socketURL
        }
        await store.receive(\.business.startVisibilityTimers)

        // Send response for the second time but change the order

        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: [snippets[1], snippets[2], snippets[0]]), nil)
        }

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippetsStates[1], snippetsStates[2], snippetsStates[0]])
        }
        await store.receive(\.business.startVisibilityTimers)
    }

    @MainActor
    func testAddingAndRemoving() async {
        let s1ID = "1"
        let s2ID = "2"
        let s3ID = "3"
        let s4ID = "4"

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!),
            .init(id: s4ID, target: URL(string: "https://news.ycombinato2.com")!)
        ]

        let snippetsStates: [TWSSnippetFeature.State] = snippets.map { .init(snippet: $0) }

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in
                    (TWSProject(listenOn: socketURL, snippets: [snippets[0], snippets[1], snippets[2]]), nil)
                }
                $0.api.getResource = { _, _ in return "" }
                $0.date.now = Date()
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippetsStates[0], snippetsStates[1], snippetsStates[2]])
            $0.socketURL = self.socketURL
            $0.snippetDates = [:]
        }
        await store.receive(\.business.startVisibilityTimers)

        // Send response for the second time but remove some and add some

        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: [snippets[0], snippets[2], snippets[3]]), nil)
        }

        await store.send(.business(.load)).finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippetsStates[0], snippetsStates[2], snippetsStates[3]])
        }
        await store.receive(\.business.startVisibilityTimers)
    }

    @MainActor
    func testSourceToAPI() async {
        let testClock = TestClock()
        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration),
            reducer: { TWSSnippetsObserverFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in (.init(listenOn: socketURL, snippets: []), nil)}
                $0.socket.get = { _, _ in .init() }
                $0.socket.connect = { _ in .makeStream().stream }
                $0.socket.closeConnection = { _ in }
                $0.continuousClock = testClock
            }
        )

        await store.send(.business(.set(source: .api))) {
            $0.source = .api
        }

        await store.receive(\.business.load)
        await store.receive(\.business.projectLoaded.success, .init(listenOn: self.socketURL, snippets: [])) {
            $0.socketURL = self.socketURL
        }
        await store.receive(\.business.startVisibilityTimers)
        await store.receive(\.business.listenForChanges)

        // Stop listening

        await store.send(.business(.stopListeningForChanges))
        await store.receive(\.business.delayReconnect)
        await store.send(.business(.stopReconnecting))
    }

    @MainActor
    func testSourceToCustomURLs() async {
        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in (TWSProject(listenOn: socketURL, snippets: []), nil)}
            }
        )

        let dummySocket = URL(string: "wss://api.thewebsnippet.com")!

        await store.send(.business(.set(source: .customURLs([])))) {
            $0.source = .customURLs([])
        }
        await store.receive(\.business.load)
        await store.receive(\.business.projectLoaded.success, .init(listenOn: dummySocket, snippets: [])) {
            $0.socketURL = dummySocket
        }
        await store.receive(\.business.startVisibilityTimers)
    }
}
