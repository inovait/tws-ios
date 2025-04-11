import Foundation
import ComposableArchitecture
import TWSSnippet
import TWSCommon
@_spi(Internals) import TWSModels

// swiftlint:disable identifier_name
private let RECONNECT_TIMEOUT: TimeInterval = 3
// swiftlint:enable identifier_name

@Reducer
public struct TWSSnippetsFeature: Sendable {

    @Dependency(\.api) var api
    @Dependency(\.socket) var socket
    @Dependency(\.continuousClock) var clock
    @Dependency(\.configuration) var configuration

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .business(action):
                return _reduce(into: &state, action: action)
            }
        }
        .forEach(\.snippets, action: \.business.snippets) {
            TWSSnippetFeature()
        }
    }

    // MARK: - Helpers

    private func _reduce(into state: inout State, action: Action.BusinessAction) -> Effect<Action> {
        switch action {

        // MARK: - Loading snippets

        case .load:
            guard state.state.canLoad
            else {
                logger.warn("Skipped loading state because of the state: \(state.state)")
                return .none
            }

            state.state = .loading

            return .run { [api] send in
                switch configuration() {
                case let config as TWSBasicConfiguration:
                    do {
                        let project = try await api.getProject(config)
                        let serverDate = project.1
                        await send(.business(.projectLoaded(.success(.init(
                            project: project.0,
                            serverDate: serverDate
                        )))))
                    } catch {
                        await send(.business(.projectLoaded(.failure(error))))
                    }
                case let config as TWSSharedConfiguration:
                    do {
                        let sharedToken = try await api.getSharedToken(config)
                        let sharedSnippet = try await api.getSnippetBySharedToken(sharedToken)
                        await send(.business(.projectLoaded(.success(.init(
                            project: sharedSnippet.0,
                            serverDate: sharedSnippet.1
                        )))))
                    }
                default:
                    return
                }
            }

        case .startVisibilityTimers(let snippets):
            var effects = [Effect<Action>]()
            let snippetTimes = state.snippetDates
            snippets.forEach { snippet in
                var snippetDateInfo = snippetTimes[snippet.id]
                if snippetDateInfo == nil {
                    snippetDateInfo = .init(serverTime: Date())
                }
                if let snippetDateInfo {
                    if let snippetVisibility = snippet.visibility {
                        if let fromUtc = snippetVisibility.fromUtc {
                            if snippetDateInfo.adaptedTime < fromUtc {
                                let duration = snippetDateInfo.adaptedTime.timeIntervalSince(fromUtc)
                                effects.append(
                                    .run { send in
                                        await send(.business(.hideSnippet(snippetId: snippet.id)))
                                        try? await clock.sleep(for: .seconds(duration))
                                        await send(.business(.showSnippet(snippetId: snippet.id)))
                                    }
                                        .cancellable(id: CancelID.showSnippet(snippet.id), cancelInFlight: true)
                                )
                            } else {
                                effects.append(
                                    .run { send in
                                        await send(.business(.showSnippet(snippetId: snippet.id)))
                                    }
                                )
                            }
                        }
                        if let untilUtc = snippetVisibility.untilUtc {
                            if snippetDateInfo.adaptedTime < untilUtc {
                                let duration = untilUtc.timeIntervalSince(snippetDateInfo.adaptedTime)
                                effects.append(
                                    .run { send in
                                        await send(.business(.showSnippet(snippetId: snippet.id)))
                                        try? await clock.sleep(for: .seconds(duration))
                                        await send(.business(.hideSnippet(snippetId: snippet.id)))
                                    }
                                        .cancellable(id: CancelID.hideSnippet(snippet.id), cancelInFlight: true)
                                )
                            } else {
                                effects.append(
                                    .run { send in
                                        await send(.business(.hideSnippet(snippetId: snippet.id)))
                                    }
                                )
                            }
                        }
                    }
                }
            }
            return .concatenate(effects)

        case let .projectLoaded(.success(project)):
            logger.info("Snippets loaded.")
            state.state = .loaded

            var effects = [Effect<Action>]()
            let snippets = project.snippets
            let newOrder = snippets.map(\.id)
            let currentOrder = state.snippets.ids
            state.socketURL = project.listenOn

            // Remove old attachments
            let currentResources = Set(state.preloadedResources.keys)
            let newResources = _getResources(of: project.project)
            for resource in currentResources.subtracting(newResources) {
                #if TESTING
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
                state.preloadedResources.removeValue(forKey: resource)
                #else
                state.$preloadedResources.withLock { _ = $0.removeValue(forKey: resource) }
                #endif
            }

            effects.append(.send(.business(.startVisibilityTimers(snippets))))

            // Update current or add new
            for snippet in snippets {
                if let date = project.serverDate {
                    state.$snippetDates[snippet.id].withLock { $0 = SnippetDateInfo(serverTime: date) }
                }
                if currentOrder.contains(snippet.id) {
                    if state.snippets[id: snippet.id]?.snippet != snippet {
                        // View needs to be forced refreshed
                        effects.append(
                            .send(
                                .business(
                                    .snippets(
                                        .element(
                                            id: snippet.id,
                                            action: .business(.snippetUpdated(
                                                snippet: snippet,
                                                preloaded: MainActor.assumeIsolated {
                                                    snippet.hasResources(for: configuration())
                                                }
                                            ))
                                        )
                                    )
                                )
                            )
                        )
                    }

                    #if TESTING
                    // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
                    state.snippets[id: snippet.id]?.snippet = snippet
                    #else
                    state.$snippets[id: snippet.id].withLock { $0?.snippet = snippet }
                    #endif

                    logger.info("Updated snippet: \(snippet.id)")
                } else {
                    let new = TWSSnippetFeature.State(snippet: snippet, preloaded: false)

                    #if TESTING
                    // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
                    state.snippets.append(new)
                    #else
                    _ = state.$snippets.withLock { $0.append(new)}
                    #endif

                    logger.info("Added snippet: \(snippet.id)")
                }
            }

            // Remove old

            for id in currentOrder.subtracting(newOrder) {
                #if TESTING
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
                state.snippets.remove(id: id)
                #else
                _ = state.$snippets.withLock { $0.remove(id: id) }
                #endif
                logger.info("Removed snippet: \(id)")
            }

            // Keep sorted
            sort(basedOn: newOrder, &state)

            return .concatenate(effects)

        case let .projectLoaded(.failure(error)):
            state.state = .failed(error)

            if let error = error as? DecodingError {
                logger.err(
                    "Failed to decode snippets: \(error)"
                )
            } else {
                logger.err(
                    "Failed to load snippets: \(error)"
                )
            }

            return .none

        // MARK: - Listening for changes via WebSocket

        case .listenForChanges:
            guard !state.isSocketConnected
            else {
                let socket = state.socketURL?.absoluteString ?? ""
                logger.info("Early return, because the socket is already connected to: \(socket)")
                return .none
            }

            guard let url = state.socketURL
            else {
                logger.err("Failed to listen for changes. URL is nil")
                assertionFailure()
                return .none
            }

            return .run { [socket, url, config = configuration()] send in
                let connectionID = await socket.get(config, url)
                let stream: AsyncStream<WebSocketEvent>
                do {
                    stream = try await socket.connect(connectionID)
                } catch {
                    await send(.business(.delayReconnect))
                    return
                }

                do {
                    try await listen(
                        connectionID: connectionID,
                        stream: stream,
                        send: send,
                        configuration: config
                    )
                } catch {
                    logger.info("Stopped listening: \(error)")
                }

                logger.info("The task used for listening to socket has completed. Closing connection.")
                await socket.closeConnection(connectionID)
            }
            .cancellable(id: CancelID.socket(configuration().id))
            .concatenate(with: .send(.business(.delayReconnect)))

        case let .isSocketConnected(isConnected):
            state.isSocketConnected = isConnected
            return .none

        case .delayReconnect:
            return .run { [clock] send in
                do {
                    try await clock.sleep(for: .seconds(RECONNECT_TIMEOUT))
                    guard !Task.isCancelled else { return }
                    logger.info("Reconnect")
                    await send(.business(.reconnectTriggered))
                } catch {
                    logger.err("Reconnecting failed: \(error)")
                }
            }
            .cancellable(id: CancelID.reconnect(configuration().id))

        case .reconnectTriggered:
            state.socketURL = nil
            return .send(.business(.load))

        case .stopListeningForChanges:
            logger.warn("Requested to stop listening for changes")
            return .cancel(id: CancelID.socket(configuration().id))

        case .stopReconnecting:
            logger.warn("Requested to stop reconnecting to the socket")
            return .cancel(id: CancelID.reconnect(configuration().id))

        // MARK: - Other

        case let .setLocalProps(props):
            let id = props.0
            let localProps = props.1
            #if TESTING
            // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
            state.snippets[id: id]?.localProps = .dictionary(localProps)
            #else
            state.$snippets[id: id].withLock { $0?.localProps = .dictionary(localProps) }
            #endif
            return .none

        case let .snippets(.element(_, action: .delegate(delegateAction))):
            switch delegateAction {
            case let .resourcesUpdated(resources):
                resources.forEach { resource in
                    #if TESTING
                    state.preloadedResources[resource.key] = resource.value
                    #else
                    state.$preloadedResources[resource.key].withLock { $0 = resource.value }
                    #endif
                }
                return .none
            }

        case .snippets:
            return .none

        case .showSnippet(snippetId: let snippetId):
            #if TESTING
            // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
            state.snippets[id: snippetId]?.isVisible = true
            #else
            state.$snippets[id: snippetId].withLock { $0?.isVisible = true }
            #endif

            return .none

        case .hideSnippet(snippetId: let snippetId):
            #if TESTING
            // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
            state.snippets[id: snippetId]?.isVisible = false
            #else
            state.$snippets[id: snippetId].withLock { $0?.isVisible = false }
            #endif

            return .none
        }
    }

    // MARK: - Helpers

    private func _getResources(of project: TWSProject) -> Set<TWSSnippet.Attachment> {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let newResources = project.allResources(headers: &headers)
        return Set(newResources)
    }
}
