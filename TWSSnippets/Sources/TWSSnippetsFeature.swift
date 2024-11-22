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
                do {
                    let project = try await api.getProject(configuration())
                    let serverDate = project.1

                    await send(.business(.projectLoaded(.success(.init(
                        project: project.0,
                        serverDate: serverDate
                    )))))
                } catch {
                    await send(.business(.projectLoaded(.failure(error))))
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
                state.preloadedResources.removeValue(forKey: resource)
            }

            effects.append(.send(.business(.startVisibilityTimers(snippets))))

            // Update current or add new
            for snippet in snippets {
                if let date = project.serverDate {
                    state.snippetDates[snippet.id] = SnippetDateInfo(serverTime: date)
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
                                                preloaded: snippet.hasResources(for: configuration())
                                            ))
                                        )
                                    )
                                )
                            )
                        )
                    }

                    state.snippets[id: snippet.id]?.snippet = snippet
                    logger.info("Updated snippet: \(snippet.id)")
                } else {
                    state.snippets.append(
                        .init(
                            snippet: snippet,
                            preloaded: false
                        )
                    )

                    logger.info("Added snippet: \(snippet.id)")
                    effects.append(.send(.business(.snippets(.element(
                        id: snippet.id,
                        action: .business(.preload)
                    )))))
                }
            }

            // Remove old

            for id in currentOrder.subtracting(newOrder) {
                state.snippets.remove(id: id)
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
            .cancellable(id: CancelID.socket(configuration()))
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
            .cancellable(id: CancelID.reconnect(configuration()))

        case .reconnectTriggered:
            state.socketURL = nil
            return .send(.business(.load))

        case .stopListeningForChanges:
            logger.warn("Requested to stop listening for changes")
            return .cancel(id: CancelID.socket(configuration()))

        case .stopReconnecting:
            logger.warn("Requested to stop reconnecting to the socket")
            return .cancel(id: CancelID.reconnect(configuration()))

        // MARK: - Other

        case let .setLocalProps(props):
            let id = props.0
            let localProps = props.1
            state.snippets[id: id]?.localProps = .dictionary(localProps)
            return .none

        case let .snippets(.element(_, action: .delegate(delegateAction))):
            switch delegateAction {
            case let .resourcesUpdated(resources):
                resources.forEach { state.preloadedResources[$0.key] = $0.value }
                return .none
            }

        case .snippets:
            return .none

        case .showSnippet(snippetId: let snippetId):
            state.snippets[id: snippetId]?.isVisible = true
            return .none

        case .hideSnippet(snippetId: let snippetId):
            state.snippets[id: snippetId]?.isVisible = false
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
