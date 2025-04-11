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

// swiftlint:disable file_length

import XCTest
@testable import TWSSnippets
@testable import TWSSnippet
@testable import TWSCommon
@_spi(Internals)
@testable import TWSModels
@testable import ComposableArchitecture

final class SnippetsTests: XCTestCase {

    let socketURL = URL(string: "https://www.google.com")!
    let configuration = TWSBasicConfiguration(id: "00000000-0000-0000-0000-000000000001")

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
        let project = TWSProject(listenOn: socketURL, snippets: snippets)
        let bundle = TWSProjectBundle(project: project, serverDate: nil)

        let store = TestStore(
            initialState: state,
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { _ in (project, nil)}
                $0.api.getResource = { _, _ in return "" }
                $0.date.now = Date()
            }
        )

        // Send response for the first time
        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        // Receive remote snippets
        await store.receive(\.business.projectLoaded.success, bundle) {
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0, preloaded: false) })
            $0.socketURL = self.socketURL
            $0.state = .loaded
        }

        await store.receive(\.business.startVisibilityTimers)

        // Send response for the second time (state must be preserved)
        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) { state in
            state.state = .loaded
        }
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

        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0, preloaded: false) })
            $0.socketURL = self.socketURL
            $0.state = .loaded
        }
        await store.receive(\.business.startVisibilityTimers)

        // Send for the second time without one element. Snippet should be removed from state
        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: [snippets[1], snippets[2]]), nil)
        }

        await store.send(.business(.load)) { state in
            state.state = .loading
        }
        .finish()

        await store.receive(\.business.projectLoaded.success) {
            $0.snippets.removeFirst()
            $0.state = .loaded
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

        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippets[0], snippets[2]].map { .init(snippet: $0, preloaded: false) })
            $0.socketURL = self.socketURL
            $0.state = .loaded
        }
        await store.receive(\.business.startVisibilityTimers)

        // Send for the second time with new element. Snippet should be added in right order
        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: snippets), nil)
        }

        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) {
            $0.snippets.insert(.init(snippet: snippets[1], preloaded: false), at: 1)
            $0.state = .loaded
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

        let snippetsStates: [TWSSnippetFeature.State] = snippets.map { .init(snippet: $0, preloaded: false) }

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

        await store.send(.business(.load)) { state in
            state.state = .loading
        }
        .finish()
        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: snippetsStates)
            $0.socketURL = self.socketURL
            $0.state = .loaded
        }
        await store.receive(\.business.startVisibilityTimers)

        // Send response for the second time but change the order

        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: [snippets[1], snippets[2], snippets[0]]), nil)
        }

        await store.send(.business(.load)) { state in
            state.state = .loading
        }
        .finish()

        await store.receive(\.business.projectLoaded.success) {
            let before = $0.snippets
            $0.snippets = .init(uniqueElements: [before[1], before[2], before[0]])
            $0.state = .loaded
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

        let snippetsStates: [TWSSnippetFeature.State] = snippets.map { .init(snippet: $0, preloaded: false) }

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

        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippetsStates[0], snippetsStates[1], snippetsStates[2]])
            $0.socketURL = self.socketURL
            $0.$snippetDates.withLock { $0 = [:] }
            $0.state = .loaded
        }
        await store.receive(\.business.startVisibilityTimers)

        // Send response for the second time but remove some and add some
        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: [snippets[0], snippets[2], snippets[3]]), nil)
        }

        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) {
            let new = [snippetsStates[0], snippetsStates[2], snippetsStates[3]]
            $0.snippets = .init(uniqueElements: new)
            $0.state = .loaded
        }

        await store.receive(\.business.startVisibilityTimers)
    }
    
    @MainActor
    func testPreloadWhenFirstRendered() async throws {
        let s1ID = "1"
        let s2ID = "2"

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!),
            .init(id: s2ID, target: URL(string: "https://www.24ur.com")!)
        ]

        let state = TWSSnippetsFeature.State(configuration: configuration)
        let project = TWSProject(listenOn: socketURL, snippets: snippets)
        let bundle = TWSProjectBundle(project: project, serverDate: nil)

        let store = TestStore(
            initialState: state,
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { _ in (project, nil)}
                $0.api.getResource = { url,_ in return url.url.absoluteString }
                $0.date.now = Date()
            }
        )
        
        await store.send(.business(.load)) {
            $0.state = .loading
        }
        
        await store.receive(\.business.projectLoaded.success) {
            $0.socketURL = self.socketURL
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0, preloaded: false) })
            $0.state = .loaded
        }
        await store.receive(\.business.startVisibilityTimers)
        
        XCTAssert(store.state.preloadedResources.isEmpty)
        
        // Open first snippet
        await store.send(\.business.snippets[id: s1ID].view.openedTWSView)
        await store.receive(\.business.snippets[id: s1ID].business.preload) {
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        await store.receive(\.business.snippets[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
        }
        // Observe preloaded resources, only first should appear
        await store.receive(\.business.snippets[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [ .init(url: snippets[0].target, contentType: .html) : snippets[0].target.absoluteString]
        }
        
        // Open second snippet
        await store.send(\.business.snippets[id: s2ID].view.openedTWSView)
        await store.receive(\.business.snippets[id: s2ID].business.preload) {
            $0.snippets[id: s2ID]?.isPreloading = true
        }
        await store.receive(\.business.snippets[id: s2ID].business.preloadCompleted) {
            $0.snippets[id: s2ID]?.isPreloading = false
            $0.snippets[id: s2ID]?.preloaded = true
        }
        // Observe preloaded resources again, two resources appear
        await store.receive(\.business.snippets[id: s2ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [
                .init(url: snippets[0].target, contentType: .html) : snippets[0].target.absoluteString,
                .init(url: snippets[1].target, contentType: .html) : snippets[1].target.absoluteString
            ]
        }
    }
    
    @MainActor
    func testResourceChanged() async throws {
        let s1ID = "1"

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!)
        ]

        let state = TWSSnippetsFeature.State(configuration: configuration)
        let project = TWSProject(listenOn: socketURL, snippets: snippets)
        let bundle = TWSProjectBundle(project: project, serverDate: nil)

        let store = TestStore(
            initialState: state,
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { _ in (project, nil)}
                $0.api.getResource = { url,_ in return url.url.absoluteString }
                $0.date.now = Date()
            }
        )
        
        await store.send(.business(.load)) {
            $0.state = .loading
        }
        
        await store.receive(\.business.projectLoaded) {
            $0.socketURL = self.socketURL
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0, preloaded: false) })
            $0.state = .loaded
        }
        await store.receive(\.business.startVisibilityTimers)
        
        // Open first snippet
        await store.send(\.business.snippets[id: s1ID].view.openedTWSView)
        await store.receive(\.business.snippets[id: s1ID].business.preload) {
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        await store.receive(\.business.snippets[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
        }
        // Observe preloaded resources, only first should appear
        await store.receive(\.business.snippets[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [ .init(url: snippets[0].target, contentType: .html) : snippets[0].target.absoluteString]
        }
        
        let changedSnippets: [TWSSnippet] = [
            TWSSnippet(id: s1ID, target: URL(string: "https://www.24ur.com")!)
        ]
        let changedProject = TWSProject(listenOn: socketURL, snippets: changedSnippets)
        store.dependencies.api.getProject = { _ in (changedProject, nil)}
        
        await store.send(\.business.load) {
            $0.state = .loading
        }
        await store.receive(\.business.projectLoaded.success) {
            $0.socketURL = self.socketURL
            $0.snippets = .init(uniqueElements: changedSnippets.map { .init(snippet: $0, preloaded: true) })
            $0.preloadedResources = [:]
            $0.state = .loaded
        }
        await store.receive(\.business.startVisibilityTimers)
        
        await store.receive(\.business.snippets[id: s1ID].business.snippetUpdated) {
            $0.snippets[id: s1ID]?.preloaded = false
        }
        
        await store.receive(\.business.snippets[id: s1ID].business.preload) {
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        
        await store.receive(\.business.snippets[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.preloaded = true
            $0.snippets[id: s1ID]?.isPreloading = false
        }
        
        await store.receive(\.business.snippets[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [ .init(url: changedSnippets[0].target, contentType: .html) : changedSnippets[0].target.absoluteString]
        }
    }
}

// swiftlint:enable file_length
