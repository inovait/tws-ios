import Foundation
import ComposableArchitecture
import TWSModels

@Reducer
public struct TWSSnippetFeature {

    @ObservableState
    public struct State: Equatable, Codable {

        public var snippet: TWSSnippet
        public var displayInfo: TWSDisplayInfo
        public var updateCount = 0

        public init(snippet: TWSSnippet) {
            self.snippet = snippet
            self.displayInfo = .init()
        }
    }

    public enum Action {

        @CasePathable
        public enum Business {
            case update(height: CGFloat, forId: String)
            case snippetUpdated
        }

        case business(Business)
    }

    public init() { }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .business(.update(height, forId)):
            if let info = state.displayInfo.displays[forId] {
                state.displayInfo.displays[forId] = info.height(height)
            } else {
                state.displayInfo.displays[forId] = .init(
                    id: forId,
                    height: height
                )
            }

            return .none

        case .business(.snippetUpdated):
            state.updateCount += 1
            return .none
        }
    }
}
