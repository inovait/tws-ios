import Foundation
import ComposableArchitecture
import TWSModels
import TWSCommon

@Reducer
public struct TWSSnippetFeature: Sendable {

    @ObservableState
    public struct State: Equatable, Codable, Sendable {

        public var snippet: TWSSnippet
        public var displayInfo: TWSDisplayInfo
        public var updateCount = 0
        public var isVisible = true

        public init(snippet: TWSSnippet) {
            self.snippet = snippet
            self.displayInfo = .init()
        }
    }

    public enum Action {

        @CasePathable
        public enum Business {
            case update(height: CGFloat, forId: String)
            case snippetUpdated(snippet: TWSSnippet?)
            case showSnippet
            case hideSnippet
            case checkResources(snippet: TWSSnippet)
        }

        @CasePathable
        public enum Delegate {
            case resourcesUpdated([TWSSnippet.Attachment: String])
        }

        case business(Business)
        case delegate(Delegate)
    }

    @Dependency(\.api) var api

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

        case let .business(.snippetUpdated(snippet)):
            if let snippet {
                state.snippet = snippet
                if snippet != state.snippet {
                    logger.info("Snippet updated from \(state.snippet) to \(snippet).")
                } else {
                    logger.info("Snippet's payload changed")
                    state.updateCount += 1
                }

                return .send(.business(.checkResources(snippet: snippet)))
            }

            return .none

        case .business(.hideSnippet):
            state.isVisible = false
            return .none

        case .business(.showSnippet):
            state.isVisible = true
            return .none

        case let .business(.checkResources(snippet)):
            return .run { [api] send in
                let resources = await preloadResources(for: snippet, using: api)
                await send(.delegate(.resourcesUpdated(resources)))
            }

        case .delegate:
            return .none
        }
    }
}
