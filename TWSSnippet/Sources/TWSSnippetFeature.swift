import Foundation
import ComposableArchitecture

@Reducer
public struct TWSSnippetFeature {

    @ObservableState
    public struct State {

        public var counter = 1

        public init(counter: Int = 1) {
            self.counter = counter
        }
    }

    public enum Action {
        case increase
        case decrease
    }

    public init() { }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .increase:
            state.counter += 1
            return .none

        case .decrease:
            state.counter -= 1
            return .none
        }
    }
}
