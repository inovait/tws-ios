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

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAPIShouldNotOverrideState() async {
        let s1ID = UUID()
        let s2ID = UUID()
        let s3ID = UUID()

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!)
        ]

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getSnippets = { snippets }
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
        }

        let newTag = UUID()
        await store.send(.business(.snippets(.element(id: s1ID, action: .business(.setTag(newTag)))))) {
            $0.snippets[id: s1ID]?.tag = newTag
        }

        // Send response for the second time (state must be preserved)
        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success)
    }

    @MainActor
    func testAPIShouldRemoveFromStateOnceNotReturned() async {
        let s1ID = UUID()
        let s2ID = UUID()
        let s3ID = UUID()

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!)
        ]

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getSnippets = { snippets }
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
        }

        // Send for the second time without one element. Snippet should be removed from state

        store.dependencies.api.getSnippets = { [snippets[1], snippets[2]] }

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets.removeFirst()
        }
    }

    @MainActor
    func testAPIShouldAddNewWhenReturned() async {
        let s1ID = UUID()
        let s2ID = UUID()
        let s3ID = UUID()

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!)
        ]

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getSnippets = { [snippets[0], snippets[2] ] }
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippets[0], snippets[2]].map { .init(snippet: $0) })
        }

        // Send for the second time with new element. Snippet should be added in right order
        store.dependencies.api.getSnippets = { snippets }

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets.insert(.init(snippet: snippets[1]), at: 1)
        }
    }

    @MainActor
    func testAPIOrderChange() async {
        let s1ID = UUID()
        let s2ID = UUID()
        let s3ID = UUID()

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!)
        ]

        let snippetsStates: [TWSSnippetFeature.State] = snippets.map { .init(snippet: $0) }

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getSnippets = { snippets }
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets = .init(uniqueElements: snippetsStates)
        }

        // Send response for the second time but change the order

        store.dependencies.api.getSnippets = { [snippets[1], snippets[2], snippets[0] ] }

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippetsStates[1], snippetsStates[2], snippetsStates[0]])
        }
    }

    @MainActor
    func testAddingAndRemoving() async {
        let s1ID = UUID()
        let s2ID = UUID()
        let s3ID = UUID()
        let s4ID = UUID()

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!),
            .init(id: s3ID, target: URL(string: "https://news.ycombinator.com")!),
            .init(id: s4ID, target: URL(string: "https://news.ycombinato2.com")!)
        ]

        let snippetsStates: [TWSSnippetFeature.State] = snippets.map { .init(snippet: $0) }

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getSnippets = { [snippets[0], snippets[1], snippets[2]] }
            }
        )

        // Send response for the first time

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippetsStates[0], snippetsStates[1], snippetsStates[2]])
        }

        // Send response for the second time but remove some and add some

        store.dependencies.api.getSnippets = { [snippets[0], snippets[2], snippets[3] ] }

        await store.send(.business(.load)).finish()
        await store.receive(\.business.snippetsLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippetsStates[0], snippetsStates[2], snippetsStates[3]])
        }
    }
}
