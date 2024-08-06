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
        // TODO:
        public var isPrivate: Bool = false

        public init(snippet: TWSSnippet, isPrivate: Bool = false) {
            self.snippet = snippet
            self.displayInfo = .init()
            self.isPrivate = isPrivate
        }
    }

    public enum Action {

        @CasePathable
        public enum Business {
            case update(height: CGFloat, forId: String)
            case snippetUpdated(target: URL?)
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

        case let .business(.snippetUpdated(target)):
            if let target, target != state.snippet.target {
                print("-> [Socket] changed from \(state.snippet.target) to \(target) and count \(state.updateCount) ~")
                state.snippet.target = target
            } else {
                print("-> [Socket] webview payload changed ~ updating count")
                state.updateCount += 1
            }
            
            return .none
        }
    }
}
