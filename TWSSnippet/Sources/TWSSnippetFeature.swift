import Foundation
import ComposableArchitecture
import TWSModels
import TWSCommon

@Reducer
public struct TWSSnippetFeature: Sendable {

    @ObservableState
    public struct State: Equatable, Codable, Sendable {

        enum CodingKeys: String, CodingKey {
            case snippet, displayInfo, updateCount, isVisible, customProps
        }

        public var snippet: TWSSnippet
        public var displayInfo: TWSDisplayInfo
        public var updateCount = 0
        public var isVisible = true
        public var localProps: TWSSnippet.Props = .dictionary([:])

        public init(snippet: TWSSnippet) {
            self.snippet = snippet
            self.displayInfo = .init()
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // MARK: - Persistent properties

            snippet = try container.decode(TWSSnippet.self, forKey: .snippet)
            displayInfo = try container.decode(TWSDisplayInfo.self, forKey: .displayInfo)

            // MARK: - Non-persistent properties - Reset on init

            isVisible = true
            updateCount = 0
            localProps = .dictionary([:])
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(snippet, forKey: .snippet)
            try container.encode(displayInfo, forKey: .displayInfo)
            try container.encode(isVisible, forKey: .isVisible)
            try container.encode(updateCount, forKey: .updateCount)
            try container.encode(localProps, forKey: .customProps)
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
                state.isVisible = true
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
