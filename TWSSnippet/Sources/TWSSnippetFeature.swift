import Foundation
import ComposableArchitecture
import TWSModels

@Reducer
public struct TWSSnippetFeature {

    @ObservableState
    public struct State: Equatable, Codable {

        // Used for unit tests and can be removed once the snippet won't be the only property anymore
        public var tag: UUID?
        public var snippet: TWSSnippet

        public init(snippet: TWSSnippet) {
            self.snippet = snippet
            self.tag = nil
        }
    }

    public enum Action {

        @CasePathable
        public enum Business {
            case setTag(UUID?)
        }

        case business(Business)
    }

    public init() { }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .business(.setTag(tag)):
            state.tag = tag
            return .none
        }
    }
}
