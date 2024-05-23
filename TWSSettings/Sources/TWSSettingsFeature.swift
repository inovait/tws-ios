import Foundation
import ComposableArchitecture

@Reducer
public struct TWSSettingsFeature {

    @ObservableState
    public struct State {

        public var counter = 1000

        public init(counter: Int = 1000) {
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
