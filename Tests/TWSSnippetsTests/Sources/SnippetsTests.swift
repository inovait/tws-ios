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
@testable import TWSLocal
@testable import TWSTriggers

final class SnippetsTests: XCTestCase {

    let socketURL = URL(string: "https://www.google.com")!
    let configuration = TWSBasicConfiguration(id: "00000000-0000-0000-0000-000000000001")
    let triggerId = TWSDefaultTriggers.sdk_init.rawValue

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
                $0.api.getResource = { _, _ in return ResourceResponse(responseUrl: nil, data:  "") }
                $0.date.now = Date()
            }
        )

        // Send response for the first time
        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        // Receive remote snippets
        await store.receive(\.business.projectLoaded.success, bundle) {
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
            $0.socketURL = self.socketURL
            $0.state = .loaded
            $0.shouldTriggerSdkInitCampaign = false
        }

        
        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)

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
                $0.api.getResource = { _, _ in return ResourceResponse(responseUrl: nil, data:  "") }
                $0.date.now = Date()
            }
        )

        // Send response for the first time

        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
            $0.socketURL = self.socketURL
            $0.state = .loaded
            $0.shouldTriggerSdkInitCampaign = false
        }

        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)

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
                $0.api.getResource = { _, _ in return ResourceResponse(responseUrl: nil, data:  "") }
                $0.date.now = Date()
            }
        )

        // Send response for the first time

        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: [snippets[0], snippets[2]].map { .init(snippet: $0) })
            $0.socketURL = self.socketURL
            $0.state = .loaded
            $0.shouldTriggerSdkInitCampaign = false
        }

        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)

        // Send for the second time with new element. Snippet should be added in right order
        store.dependencies.api.getProject = { [socketURL] _ in
            (TWSProject(listenOn: socketURL, snippets: snippets), nil)
        }

        await store.send(.business(.load)) { state in
            state.state = .loading
        }

        await store.receive(\.business.projectLoaded.success) {
            $0.snippets.insert(.init(snippet: snippets[1]), at: 1)
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

        let snippetsStates: [TWSSnippetFeature.State] = snippets.map { .init(snippet: $0) }

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in (TWSProject(listenOn: socketURL, snippets: snippets), nil)}
                $0.api.getResource = { _, _ in return ResourceResponse(responseUrl: nil, data:  "") }
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
            $0.shouldTriggerSdkInitCampaign = false
        }

        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)

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

        let snippetsStates: [TWSSnippetFeature.State] = snippets.map { .init(snippet: $0) }

        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in
                    (TWSProject(listenOn: socketURL, snippets: [snippets[0], snippets[1], snippets[2]]), nil)
                }
                $0.api.getResource = { _, _ in return ResourceResponse(responseUrl: nil, data:  "") }
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
            $0.shouldTriggerSdkInitCampaign = false
        }

        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)

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

        let store = TestStore(
            initialState: state,
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { _ in (project, nil)}
                $0.api.getResource = { url, _ in return ResourceResponse(responseUrl: url.url, data: url.url.absoluteString)  }
                $0.date.now = Date()
            }
        )
        
        await store.send(.business(.load)) {
            $0.state = .loading
        }
        
        await store.receive(\.business.projectLoaded.success) {
            $0.socketURL = self.socketURL
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
            $0.state = .loaded
            $0.shouldTriggerSdkInitCampaign = false
        }

        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)
        
        XCTAssert(store.state.preloadedResources.isEmpty)
        
        // Open first snippet
        await store.send(\.business.snippets[id: s1ID].view.openedTWSView)
        await store.receive(\.business.snippets[id: s1ID].business.preload) {
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        await store.receive(\.business.snippets[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
            $0.snippets[id: s1ID]?.htmlContent = snippets[0].target.absoluteString
        }
        // Observe preloaded resources, only first should appear
        await store.receive(\.business.snippets[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [ .init(url: snippets[0].target, contentType: .html) : .init(responseUrl: snippets[0].target, data: snippets[0].target.absoluteString)]
        }
        
        // Open second snippet
        await store.send(\.business.snippets[id: s2ID].view.openedTWSView)
        await store.receive(\.business.snippets[id: s2ID].business.preload) {
            $0.snippets[id: s2ID]?.isPreloading = true
        }
        await store.receive(\.business.snippets[id: s2ID].business.preloadCompleted) {
            $0.preloadedResources = [.init(url: snippets[0].target, contentType: .html) : .init(responseUrl: snippets[0].target, data: snippets[0].target.absoluteString)]
            $0.snippets[id: s2ID]?.isPreloading = false
            $0.snippets[id: s2ID]?.preloaded = true
            $0.snippets[id: s2ID]?.htmlContent = snippets[1].target.absoluteString
        }
        // Observe preloaded resources again, two resources appear
        await store.receive(\.business.snippets[id: s2ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [
                .init(url: snippets[0].target, contentType: .html) : .init(responseUrl: snippets[0].target, data: snippets[0].target.absoluteString),
                .init(url: snippets[1].target, contentType: .html) : .init(responseUrl: snippets[1].target, data: snippets[1].target.absoluteString)
            ]
        }
    }
    
    @MainActor
    func testResourceChangedWithSocket() async throws {
        let s1ID = "1"

        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.google.com")!)
        ]

        var state = TWSSnippetsFeature.State(configuration: configuration)
        state.socketURL = socketURL
        let project = TWSProject(listenOn: socketURL, snippets: snippets)
        
        let clock = TestClock()
        let stream = AsyncStream<WebSocketEvent>.makeStream()
        let store = TestStore(
            initialState: state,
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { _ in (project, nil)}
                $0.api.getResource = { url,_ in ResourceResponse(responseUrl: url.url, data: url.url.absoluteString) }
                $0.date.now = Date()
                $0.socket.get = { _, _ in .init() }
                $0.socket.connect = { _ in stream.stream }
                $0.socket.closeConnection = { _ in }
                $0.socket.listen = { _ in }
                $0.continuousClock = clock
            }
        )
        
        await store.send(.business(.listenForChanges))
        
        stream.continuation.yield(.didConnect)
        await store.receive(\.business.isSocketConnected, true) {
            $0.isSocketConnected = true
        }
        
        await store.receive(\.business.load) {
            $0.state = .loading
        }
        
        await store.receive(\.business.projectLoaded.success, timeout: NSEC_PER_SEC) {
            $0.socketURL = self.socketURL
            $0.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
            $0.state = .loaded
            $0.shouldTriggerSdkInitCampaign = false
        }

        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)
            
        // Open the snippet
        await store.send(\.business.snippets[id: s1ID].view.openedTWSView)
        
        await store.receive(\.business.snippets[id: s1ID].business.preload) {
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        
        await store.receive(\.business.snippets[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
            $0.snippets[id: s1ID]?.htmlContent = snippets[0].target.absoluteString
        }

        await store.receive(\.business.snippets[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [
                .init(url: snippets[0].target, contentType: .html) : .init(responseUrl: snippets[0].target, data: snippets[0].target.absoluteString)
            ]
        }
        
        let changedURL = URL(string: "https://www.example.com")!
        
        stream.continuation.yield(.receivedMessage(SocketMessage(id: snippets[0].id, type: .updated, snippet: .init(id: snippets[0].id, target: changedURL))))
        
        await store.receive(\.business.snippets[id: s1ID].business.snippetUpdated) {
            // Imporatant that preloaded is reset to false when update is recieved since we can not observe if static or dynamic resources changed
            $0.snippets[id: s1ID]?.preloaded = false
            $0.snippets[id: s1ID]?.snippet.target = changedURL
        }
        
        await store.receive(\.business.startVisibilityTimers)
        
        // Open the same snippet for the second time and resources have to be preloaded again
        await store.send(\.business.snippets[id: s1ID].view.openedTWSView)
        
        await store.receive(\.business.snippets[id: s1ID].business.preload) {
            if let snippet = $0.snippets[id: s1ID] {
                XCTAssert(!snippet.preloaded)
            } else {
                XCTAssert(false)
            }
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        
        await store.receive(\.business.snippets[id: s1ID].business.preloadCompleted) {
            $0.preloadedResources = [.init(url: snippets[0].target, contentType: .html) : .init(responseUrl: snippets[0].target, data: snippets[0].target.absoluteString)]
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
            $0.snippets[id: s1ID]?.htmlContent = changedURL.absoluteString
        }

        await store.receive(\.business.snippets[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [
                .init(url: snippets[0].target, contentType: .html): .init(responseUrl: snippets[0].target, data: snippets[0].target.absoluteString),
                .init(url: changedURL, contentType: .html): .init(responseUrl: changedURL, data: changedURL.absoluteString)
            ]
        }
        
        // Stop listening
        await store.send(.business(.stopListeningForChanges))
        await store.receive(\.business.delayReconnect)
        await store.send(.business(.stopReconnecting))
    }
    
    @MainActor
    func testResourcesChangedBetweenLaunches() async throws {
        // Remote snippets
        let s1ID = "1"
        let url = URL(string: "https://www.google.com")!

        let remoteSnippets: [TWSSnippet] = [
            .init(id: s1ID, target: url)
        ]
        
        let staticResources = "Static Resource"
        
        // Mock persistant storages
        var cachedSnippets: [TWSSnippet] = []
        var cachedPreloadedResources: [TWSSnippet.Attachment: ResourceResponse] = [:]
        
        let storeFirstLaunch = TestStore(
            initialState: TWSSnippetsFeature.State(
                configuration: configuration,
                snippets: cachedSnippets,
                preloadedResources: cachedPreloadedResources
            ),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in return (.init(listenOn: socketURL, snippets: remoteSnippets), nil)}
                $0.api.getResource = { [staticResources] _, _ in return ResourceResponse(responseUrl: url, data: staticResources) }
                $0.date.now = Date()
            })
        
        await storeFirstLaunch.send(.business(.load)) {
            $0.state = .loading
        }
        
        await storeFirstLaunch.receive(\.business.projectLoaded.success) {
            $0.snippets = .init(uniqueElements: remoteSnippets.map { .init(snippet: $0) })
            $0.state = .loaded
            $0.socketURL = self.socketURL
            cachedSnippets = remoteSnippets
            $0.shouldTriggerSdkInitCampaign = false
        }

        await storeFirstLaunch.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await storeFirstLaunch.receive(\.business.startVisibilityTimers)
        
        await storeFirstLaunch.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await storeFirstLaunch.receive(\.business.trigger[id: triggerId].business.campaignLoaded)
        
        await storeFirstLaunch.send(\.business.snippets[id: s1ID].view.openedTWSView)
        
        await storeFirstLaunch.receive(\.business.snippets[id: s1ID].business.preload) {
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        await storeFirstLaunch.receive(\.business.snippets[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
            $0.snippets[id: s1ID]?.htmlContent = staticResources
        }
        
        await storeFirstLaunch.receive(\.business.snippets[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [
                .init(url: remoteSnippets[0].target, contentType: .html) : .init(responseUrl: remoteSnippets[0].target, data: staticResources),
            ]
            cachedPreloadedResources = $0.preloadedResources
        }
        
        XCTAssert(!cachedSnippets.isEmpty)
        XCTAssert(!cachedPreloadedResources.isEmpty)
        
        
        let changedStaticResources = "New Static Resources"
        
        // Create a new store with cached data as if you restarted the app
        let storeSecondLaunch = TestStore(
            initialState: TWSSnippetsFeature.State(
                configuration: configuration,
                snippets: cachedSnippets,
                preloadedResources: cachedPreloadedResources
            ),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { [socketURL] _ in return (.init(listenOn: socketURL, snippets: remoteSnippets), nil)}
                $0.api.getResource = { _, _ in return ResourceResponse(responseUrl: url, data: changedStaticResources) }
                $0.date.now = Date()
            })
        
        await storeSecondLaunch.send(\.business.load) {
            $0.state = .loading
        }
        
        await storeSecondLaunch.receive(\.business.projectLoaded) {
            $0.state = .loaded
            $0.socketURL = self.socketURL
            $0.shouldTriggerSdkInitCampaign = false
        }
        
        await storeSecondLaunch.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await storeSecondLaunch.receive(\.business.startVisibilityTimers)
        
        await storeSecondLaunch.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        
        await storeSecondLaunch.receive(\.business.trigger[id: triggerId].business.campaignLoaded)
            
        // Open the same snippet as before
        await storeSecondLaunch.send(\.business.snippets[id: s1ID].view.openedTWSView)
        
        await storeSecondLaunch.receive(\.business.snippets[id: s1ID].business.preload) {
            if let snippet = $0.snippets[id: s1ID] {
                // This allows resources to be preloaded on each run
                XCTAssert(!snippet.preloaded)
            } else {
                XCTAssert(false)
            }
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        
        await storeSecondLaunch.receive(\.business.snippets[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
            $0.snippets[id: s1ID]?.htmlContent = changedStaticResources
        }
        
        await storeSecondLaunch.receive(\.business.snippets[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [
                .init(url: remoteSnippets[0].target, contentType: .html) : .init(responseUrl: remoteSnippets[0].target, data: changedStaticResources)
            ]
            
            // Preloaded resource got removed and new one added
            XCTAssert(cachedPreloadedResources != $0.preloadedResources)
        }
    }
    
    @MainActor
    func testPreloadTiming() async throws {
        let snippetUrl = URL(string: "https://www.test.com")!
        let dynamicResourceURL1 = URL(string: "https://www.test.com/dynamicResource/1")!
        let dynamicResourceURL2 = URL(string: "https://www.test.com/dynamicResource/2")!
        
        let snippet: TWSSnippet = .init(
            id: "1",
            target: snippetUrl,
            dynamicResources: [
                .init(url: dynamicResourceURL1, contentType: .css),
                .init(url: dynamicResourceURL2, contentType: .javascript)
            ])
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession(configuration: config)
        
        let reducer = TWSSnippetFeature()
        let store = TestStore(
            initialState: TWSSnippetFeature.State(snippet: snippet),
            reducer: { reducer },
            withDependencies: {
                $0.api.getResource = { attachment, headers in
                    do {
                        try await urlSession.data(from: attachment.url)
                    } catch {}
                    return ResourceResponse(responseUrl: attachment.url, data: attachment.url.absoluteString)}
                $0.date.now = Date()
            })
        
        let preloadedResources = await reducer.preloadAndInjectResources(for: snippet, using: store.dependencies.api)
        
        let timestampsForTarget = TimeStampedRequests.stampedRequests[snippetUrl]!
        
        for timestamp in TimeStampedRequests.stampedRequests.filter { $0.key != snippetUrl } {
            XCTAssert(timestampsForTarget.finish < timestamp.value.start)
        }
    }
    
    @MainActor
    func testLocalSnippetsManager() async throws {
        let s1ID: String = "1"
        let snippetUrl1 = URL(string: "https://www.test.com")!
        
        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: snippetUrl1)
        ]
        
        let store = TestStore(
            initialState: TWSLocalSnippetsReducer.State.init(),
            reducer: { TWSLocalSnippetsReducer() },
            withDependencies: {
                $0.api.getResource = { item, _ in .init(responseUrl: item.url, data: item.url.absoluteString) }
            })
        
        // Locally save snippet
        await store.send(.business(.saveLocalSnippet(snippets[0]))) {
            $0.snippets = .init([.init(snippet: snippets[0])])
        }
        
        // open twsView
        await store.send(.business(.snippetAction(.element(id: s1ID, action: .view(.openedTWSView)))))
        
        await store.receive(\.business.snippetAction[id: s1ID].business.preload) {
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        await store.receive(\.business.snippetAction[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
            $0.snippets[id: s1ID]?.htmlContent = snippets[0].target.absoluteString
        }
        
        await store.receive(\.business.snippetAction[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [.init(url: snippetUrl1, contentType: .html): .init(responseUrl: snippetUrl1, data: snippetUrl1.absoluteString)]
        }
    }
    
    @MainActor
    func testLocalSnippetsManagerResourceInjection() async throws {
        let s1ID: String = "1"
        let s2ID: String = "2"
        let s3ID: String = "3"
        
        let snippetUrl1 = URL(string: "https://www.test1.com")!
        let snippetUrl2 = URL(string: "https://www.test2.com")!
        let snippetUrl3 = URL(string: "https://www.test3.com")!
        
        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: snippetUrl1),
            .init(id: s2ID, target: snippetUrl2),
            .init(id: s3ID, target: snippetUrl3)
        ]
        
        let cssToInject: TWSRawCSS = .init("body { color: red; }")
        let jsToInject: TWSRawJS = .init("alert('Hello World!')")
        
        let response1 =
                    """
                        <html anything goes here>
                            <head>
                                some content here
                            </head>
                            <body>
                                some content here
                            </body>
                        </html>
                        """
        
        let response2 =
                    """
                        <html anything goes here>
                            <body>
                                some content here
                            </body>
                        </html>
                        """
        
        let response3 =
                    """
                        <body>
                            some content here
                        </body>
                        """
        
        let expectedResponse1 =
                    """
                        <html anything goes here>
                            <head>
                                some content here
                            <style>body { color: red; }</style><script>alert('Hello World!')</script></head>
                            <body>
                                some content here
                            </body>
                        </html>
                        """
        
        let expectedResponse2 =
                    """
                        <html anything goes here><script>alert('Hello World!')</script><style>body { color: red; }</style>
                            <body>
                                some content here
                            </body>
                        </html>
                        """
        
        let expectedResponse3 =
                    """
                        <script>alert('Hello World!')</script><body>
                            some content here
                        </body><style>body { color: red; }</style>
                        """
        
        let store = TestStore(
            initialState: TWSLocalSnippetsReducer.State.init(),
            reducer: { TWSLocalSnippetsReducer() },
            withDependencies: {
                $0.api.getResource = { item, _ in
                    switch item.url {
                    case snippetUrl1:
                        return .init(responseUrl: snippetUrl1, data: response1)
                    case snippetUrl2:
                        return .init(responseUrl: snippetUrl2, data: response2)
                    case snippetUrl3:
                        return .init(responseUrl: snippetUrl3, data: response3)
                    default:
                        return .init(responseUrl: nil, data: "")
                    }
                }
            })
        
        
        // Snippets follow local snippet flow
        await store.send(.business(.saveLocalSnippet(snippets[0]))) {
            $0.snippets = .init([.init(snippet: snippets[0])])
        }
        
        await store.send(.business(.snippetAction(.element(id: snippets[0].id, action: .business(.setLocalDynamicResources([.css(cssToInject), .js(jsToInject)])))))) {
            $0.snippets[id: s1ID]?.localDynamicResources = [.css(cssToInject), .js(jsToInject)]
        }
        
        await store.send(.business(.snippetAction(.element(id: s1ID, action: .view(.openedTWSView)))))
        
        await store.receive(\.business.snippetAction[id: s1ID].business.preload) {
            $0.snippets[id: s1ID]?.isPreloading = true
        }
        await store.receive(\.business.snippetAction[id: s1ID].business.preloadCompleted) {
            $0.snippets[id: s1ID]?.isPreloading = false
            $0.snippets[id: s1ID]?.preloaded = true
            $0.snippets[id: s1ID]?.htmlContent = expectedResponse1
        }
        
        await store.receive(\.business.snippetAction[id: s1ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [.init(url: snippetUrl1, contentType: .html): .init(responseUrl: snippetUrl1, data: expectedResponse1)]
        }
        
        var stateCopy = store.state
        
        await store.send(.business(.saveLocalSnippet(snippets[1]))) {
            $0.snippets = .init([stateCopy.snippets[id: s1ID]!, .init(snippet: snippets[1])])
        }
        
        await store.send(.business(.snippetAction(.element(id: snippets[1].id, action: .business(.setLocalDynamicResources([.css(cssToInject), .js(jsToInject)])))))) {
            $0.snippets[id: s2ID]?.localDynamicResources = [.css(cssToInject), .js(jsToInject)]
        }
        
        await store.send(.business(.snippetAction(.element(id: s2ID, action: .view(.openedTWSView)))))
        
        await store.receive(\.business.snippetAction[id: s2ID].business.preload) {
            $0.snippets[id: s2ID]?.isPreloading = true
        }
        await store.receive(\.business.snippetAction[id: s2ID].business.preloadCompleted) {
            $0.snippets[id: s2ID]?.isPreloading = false
            $0.snippets[id: s2ID]?.preloaded = true
            $0.snippets[id: s2ID]?.htmlContent = expectedResponse2
        }
        
        await store.receive(\.business.snippetAction[id: s2ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [
                .init(url: snippetUrl1, contentType: .html): .init(responseUrl: snippetUrl1, data: expectedResponse1),
                .init(url: snippetUrl2, contentType: .html): .init(responseUrl: snippetUrl2, data: expectedResponse2)
            ]
        }
        
        stateCopy = store.state
        
        await store.send(.business(.saveLocalSnippet(snippets[2]))) {
            $0.snippets = .init([stateCopy.snippets[id: s1ID]!, stateCopy.snippets[id: s2ID]!, .init(snippet: snippets[2])])
        }

        await store.send(.business(.snippetAction(.element(id: snippets[2].id, action: .business(.setLocalDynamicResources([.css(cssToInject), .js(jsToInject)])))))) {
            $0.snippets[id: s3ID]?.localDynamicResources = [.css(cssToInject), .js(jsToInject)]
        }
        
        await store.send(.business(.snippetAction(.element(id: s3ID, action: .view(.openedTWSView)))))
        
        await store.receive(\.business.snippetAction[id: s3ID].business.preload) {
            $0.snippets[id: s3ID]?.isPreloading = true
        }
        await store.receive(\.business.snippetAction[id: s3ID].business.preloadCompleted) {
            $0.snippets[id: s3ID]?.isPreloading = false
            $0.snippets[id: s3ID]?.preloaded = true
            $0.snippets[id: s3ID]?.htmlContent = expectedResponse3
        }
        
        await store.receive(\.business.snippetAction[id: s3ID].delegate.resourcesUpdated) {
            $0.preloadedResources = [
                .init(url: snippetUrl1, contentType: .html): .init(responseUrl: snippetUrl1, data: expectedResponse1),
                .init(url: snippetUrl2, contentType: .html): .init(responseUrl: snippetUrl2, data: expectedResponse2),
                .init(url: snippetUrl3, contentType: .html): .init(responseUrl: snippetUrl3, data: expectedResponse3)
            ]
        }
        
        
    }
    
    @MainActor
    func testEmptyTriggerResult() async throws {
        let s1ID = "1"
        let s2ID = "2"
        
        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.test1.com")!),
            .init(id: s2ID, target: URL(string: "https://www.test2.com")!)
        ]
        
        var state = TWSSnippetsFeature.State(configuration: configuration, snippets: snippets)
        state.socketURL = socketURL
        let project = TWSProject(listenOn: socketURL, snippets: snippets)
        
        let store = TestStore(
            initialState: state,
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { _ in (project, nil)}
                $0.api.getResource = { url,_ in ResourceResponse(responseUrl: url.url, data: url.url.absoluteString) }
                $0.api.getCampaigns = { _, _ in .init(snippets: [])}
                $0.date.now = Date()
            })
        
    
        await store.send(.business(.load)) {
            $0.state = .loading
        }
        
        await store.receive(\.business.projectLoaded.success) {
            $0.state = .loaded
            $0.shouldTriggerSdkInitCampaign = false
        }
        
        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)
    }
    
    @MainActor
    func testTriggerResult() async throws {
        let s1ID = "1"
        let s2ID = "2"
        
        let snippets: [TWSSnippet] = [
            .init(id: s1ID, target: URL(string: "https://www.test1.com")!),
            .init(id: s2ID, target: URL(string: "https://www.test2.com")!)
        ]
        
        var state = TWSSnippetsFeature.State(configuration: configuration, snippets: snippets)
        state.socketURL = socketURL
        let project = TWSProject(listenOn: socketURL, snippets: [])
        
        let store = TestStore(
            initialState: TWSSnippetsFeature.State(configuration: configuration, snippets: []),
            reducer: { TWSSnippetsFeature() },
            withDependencies: {
                $0.api.getProject = { _ in (project, nil)}
                $0.api.getResource = { url,_ in ResourceResponse(responseUrl: url.url, data: url.url.absoluteString) }
                $0.api.getCampaigns = { _, _ in .init(snippets: snippets)}
                $0.date.now = Date()
            })
        
    
        await store.send(.business(.load)) {
            $0.state = .loading
        }
        
        await store.receive(\.business.projectLoaded.success) {
            $0.socketURL = self.socketURL
            $0.state = .loaded
            $0.shouldTriggerSdkInitCampaign = false
        }
        
        await store.receive(\.business.sendTrigger) {
            $0.campaigns = [.init(trigger: self.triggerId)]
        }
        
        await store.receive(\.business.startVisibilityTimers)
        await store.receive(\.business.trigger[id: triggerId].business.checkTrigger)
        await store.receive(\.business.trigger[id: triggerId].business.campaignLoaded)
        
        var snippetStates: IdentifiedArrayOf<TWSSnippetFeature.State> = .init([.init(snippet: snippets[0])])
        //All recieved snippets should be opened if they belong to the campaign
        await store.receive(\.business.trigger[id: triggerId].delegate.openOverlay) {
            $0.campaignSnippets = snippetStates
        }
        snippetStates.append(.init(snippet: snippets[1]))
        await store.receive(\.business.trigger[id: triggerId].delegate.openOverlay) {
            $0.campaignSnippets = snippetStates
        }
        
        await store.receive(\.delegate.openOverlay)
        await store.receive(\.delegate.openOverlay)
    }
}

struct TimeStampedRequests {
    private static let queue = DispatchQueue(label: "TimeStampedRequests.queue")
    nonisolated(unsafe) private(set) static var stampedRequests: [URL: TimestampedRequest] = [:]
    
    static func markStart(url: URL) {
        queue.sync {
            stampedRequests.updateValue(.init(), forKey: url)
        }
    }
    
    static func markFinished(url: URL) {
        queue.sync {
            var currentValue = stampedRequests[url]!
            currentValue.finish = Date().timeIntervalSince1970
            stampedRequests.updateValue(currentValue, forKey: url)
        }
    }
    
    class TimestampedRequest {
        let start: Double
        var finish: Double
        
        init() {
            self.start = Date().timeIntervalSince1970
            self.finish = Date.distantFuture.timeIntervalSince1970
        }
    }
}

class MockURLProtocol: URLProtocol {
    var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data)) = { req in
        return (HTTPURLResponse(url: req.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil), req.url!.absoluteString.data(using: .utf8)!)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        do {
            let (response, data) = try requestHandler(request)
            TimeStampedRequests.markStart(url: request.url!)
            
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            TimeStampedRequests.markFinished(url: request.url!)
            
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// swiftlint:enable file_length
