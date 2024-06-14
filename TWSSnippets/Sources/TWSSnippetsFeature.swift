import Foundation
import ComposableArchitecture
import TWSSnippet
import TWSCommon
import TWSModels

// swiftlint:disable identifier_name
private let RECONNECT_TIMEOUT: TimeInterval = 3
// swiftlint:enable identifier_name

@Reducer
public struct TWSSnippetsFeature {

    @ObservableState
    public struct State: Equatable {

        @Shared(.snippets) public internal(set) var snippets
        @Shared(.source) public internal(set) var source

        public init() { }
    }

    public enum Action {

        @CasePathable
        public enum BusinessAction {
            case load
            case snippetsLoaded(Result<[TWSSnippet], Error>)
            case listenForChanges
            case reconnect
            case stopListeningForChanges
            case stopReconnecting
            case listenForChangesResponse(Result<URL, Error>)
            case snippets(IdentifiedActionOf<TWSSnippetFeature>)
            case set(source: TWSSource)
        }

        case business(BusinessAction)

    }

    @Dependency(\.api) var api
    @Dependency(\.socket) var socket
    @Dependency(\.continuousClock) var clock

    public init() { }

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
            switch state.source {
            case .api:
                break

            case let .customURLs(urls):
                let snippets = _generateCustomSnippets(urls: urls)
                return .send(.business(.snippetsLoaded(.success(snippets))))

            @unknown default:
                break
            }

            return .run { [api] send in
                do {
                    let snippets = try await api.getSnippets()
                    await send(.business(.snippetsLoaded(.success(snippets))))
                } catch {
                    await send(.business(.snippetsLoaded(.failure(error))))
                }
            }

        case let .snippetsLoaded(.success(snippets)):
            let newOrder = snippets.map(\.id)
            let currentOrder = state.snippets.ids

            // Update current or add new

            for snippet in snippets {
                if currentOrder.contains(snippet.id) {
                    state.snippets[id: snippet.id]?.snippet = snippet
                } else {
                    state.snippets.append(
                        .init(snippet: snippet)
                    )
                }
            }

            // Remove old

            for id in currentOrder.subtracting(newOrder) {
                state.snippets.remove(id: id)
            }

            // Keep sorted
            _sort(basedOn: newOrder, &state)

            return .none

        case let .snippetsLoaded(.failure(error)):
            print("Snippets error loading snippets", error)
            return .none

        // MARK: - Listening for changes via WebSocket

        case .listenForChanges:
            switch state.source {
            case .api:
                break

            case .customURLs:
                return .none

            @unknown default:
                break
            }

            return .run { [api] send in
                do {
                    let socketURL = try await api.getSocket()
                    await send(.business(.listenForChangesResponse(.success(socketURL))))
                } catch {
                    await send(.business(.listenForChangesResponse(.failure(error))))
                }
            }

        case let .listenForChangesResponse(.success(url)):
            return .run { [socket, url] send in
                print("--> start")
                let connectionID = await socket.get(url)
                let stream: AsyncStream<WebSocketEvent>
                do {
                    stream = try await socket.connect(connectionID)
                } catch {
                    await send(.business(.reconnect))
                    return
                }

            mainLoop: for await event in stream {
                    switch event {
                    case .didConnect:
                        // TODO: Add logs
                        print("-> did connect", Date())
                        var task: Task<Void, Never>?

                        await send(.business(.load))
                        await withTaskCancellationHandler {
                            task = Task {
                                while !Task.isCancelled {
                                    do {
                                        try await socket.listen(connectionID)
                                    } catch {
                                        print("-> error")
                                        break
                                    }
                                }
                            }
                        } onCancel: { [task] in
                            print("-> Cancelled")
                            task?.cancel()
                        }

                    case .didDisconnect:
                        // TODO: Add logs
                        print("-> did disconnect", Date())
                        break mainLoop

                    case let .receivedMessage(data):
                        print("-> did receive a message")
//                        await send(.business(.load) // TODO: A
                        // TODO: Add logs
                        await send(.business(.load))
                    }
                }

                print("--> end")
                await socket.closeConnection(connectionID)
            }
            .cancellable(id: CancelID.socket)
            .concatenate(with: .send(.business(.reconnect)))

        case .reconnect:
            print("-> reconnect")
            return .run { send in
                do {
                    try await clock.sleep(for: .seconds(RECONNECT_TIMEOUT))
                    await send(.business(.listenForChanges))
                } catch {
                    // TODO: ??
                }
            }
            .cancellable(id: CancelID.reconnect)

        case let .listenForChangesResponse(.failure(error)):
            // TODO: Try again?
            return .none

        case .stopListeningForChanges:
            return .cancel(id: CancelID.socket)

        case .stopReconnecting:
            return .cancel(id: CancelID.reconnect)

        // MARK: - Other

        case let .set(source):
            state.source = source

            switch source {
            case .api:
                return .send(.business(.load))
                    .merge(with: .send(.business(.listenForChanges)))

            case .customURLs:
                return .send(.business(.load))

            @unknown default:
                return .send(.business(.load))
            }

        case .snippets:
            return .none
        }
    }

    // MARK: - Helpers

    private func _sort(basedOn orderedIDs: [UUID], _ state: inout State) {
        var orderDict = [UUID: Int]()
        for (index, id) in orderedIDs.enumerated() {
            orderDict[id] = index
        }

        state.snippets.sort(by: {
            let idx1 = orderDict[$0.id] ?? Int.max
            let idx2 = orderDict[$1.id] ?? Int.max
            return idx1 < idx2
        })
    }

    private func _generateCustomSnippets(urls: [URL]) -> [TWSSnippet] {
        let uuidGenerator = IncrementingUUIDGenerator()
        return urls.map {
            .init(
                id: uuidGenerator(),
                target: $0
            )
        }
    }
}

private extension TWSSnippetsFeature {
    enum CancelID: Hashable {
        case socket, reconnect
    }
}

private class IncrementingUUIDGenerator: @unchecked Sendable {

    private var sequence = 0

    func callAsFunction() -> UUID {
        defer {
            self.sequence += 1
        }

        return UUID(self.sequence)
    }
}
