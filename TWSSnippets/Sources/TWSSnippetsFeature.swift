import Foundation
import ComposableArchitecture
import TWSSnippet
import TWSCommon
import TWSModels

@Reducer
public struct TWSSnippetsFeature {

    @ObservableState
    public struct State {

        @Shared(.snippets) public internal(set) var snippets

        public init() { }
    }

    public enum Action {

        @CasePathable
        public enum BusinessAction {
            case load
            case snippetsLoaded(Result<[TWSSnippet], Error>)
            case snippets(IdentifiedActionOf<TWSSnippetFeature>)
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
            return .run { send in
                do {
                    let snippets = try await api.getSnippets()
                    await send(.business(.snippetsLoaded(.success(snippets))))
                } catch {
                    await send(.business(.snippetsLoaded(.failure(error))))
                }
            }

        case let .snippetsLoaded(.success(snippets)):
            state.snippets = .init(uniqueElements: snippets.map { .init(snippet: $0) })
            return .none

        case let .snippetsLoaded(.failure(error)):
            print("Error loading snippets", error)
            return .none

        case .snippets:
            return .none
        }
    }
}
