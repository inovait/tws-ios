import Foundation
import ComposableArchitecture
import TWSSnippet
import TWSCommon
import TWSModels

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
            case snippets(IdentifiedActionOf<TWSSnippetFeature>)
            case set(source: TWSSource)
        }

        case business(BusinessAction)

    }

    @Dependency(\.api) var api

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
            logger.logErr(message: "Snippets error loading snippets: " + error.localizedDescription)
            return .none

        case let .set(source):
            state.source = source
            return .send(.business(.load))

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

private class IncrementingUUIDGenerator: @unchecked Sendable {

    private var sequence = 0

    func callAsFunction() -> UUID {
        defer {
            self.sequence += 1
        }

        return UUID(self.sequence)
    }
}
