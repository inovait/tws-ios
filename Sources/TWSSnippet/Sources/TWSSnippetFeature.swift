import Foundation
import ComposableArchitecture
@_spi(Internals) import TWSModels
import TWSCommon

@Reducer
public struct TWSSnippetFeature: Sendable {

    @ObservableState
    public struct State: Equatable, Codable, Sendable {

        enum CodingKeys: String, CodingKey {
            case snippet, preloaded, isPreloading, isVisible, customProps
        }

        public var snippet: TWSSnippet
        public var preloaded: Bool = false
        public var isVisible = true
        public var localProps: TWSSnippet.Props = .dictionary([:])

        var isPreloading = false

        public init(
            snippet: TWSSnippet
        ) {
            self.snippet = snippet
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // MARK: - Persistent properties ~ match with init

            snippet = try container.decode(TWSSnippet.self, forKey: .snippet)

            // MARK: - Non-persistent properties - Reset on init
            preloaded = false
            isVisible = true
            isPreloading = false
            localProps = .dictionary([:])
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(snippet, forKey: .snippet)
            try container.encode(preloaded, forKey: .preloaded)
            try container.encode(isPreloading, forKey: .isPreloading)
            try container.encode(isVisible, forKey: .isVisible)
            try container.encode(localProps, forKey: .customProps)
        }
    }

    public enum Action {

        @CasePathable
        public enum Business {
            case snippetUpdated(snippet: TWSSnippet)
            case showSnippet
            case hideSnippet
            case preload
            case preloadCompleted([TWSSnippet.Attachment: ResourceResponse])
        }
        
        @CasePathable
        public enum View {
            case openedTWSView
        }

        @CasePathable
        public enum Delegate {
            case resourcesUpdated([TWSSnippet.Attachment: ResourceResponse])
        }

        case business(Business)
        case delegate(Delegate)
        case view(View)
    }

    @Dependency(\.api) var api

    public init() { }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.openedTWSView):
            return .send(.business(.preload))
            
        case let .business(.snippetUpdated(snippet)):
            state.snippet = snippet
            state.preloaded = false
            state.isVisible = true
            if snippet != state.snippet {
                logger.info("Snippet updated from \(state.snippet) to \(snippet).")
            } else {
                logger.info("Snippet's payload changed")
            }

            return .none

        case .business(.hideSnippet):
            state.isVisible = false
            return .none

        case .business(.showSnippet):
            state.isVisible = true
            return .none

        case .business(.preload):
            guard !state.isPreloading else { return .none }
            state.isPreloading = true

            return .run { [api, snippet = state.snippet] send in
                let resources = await preloadResources(for: snippet, using: api)
                await send(.business(.preloadCompleted(resources)))
            }

        case let .business(.preloadCompleted(resources)):
            state.preloaded = true
            state.isPreloading = false
            return .send(.delegate(.resourcesUpdated(resources)))

        case .delegate:
            return .none
        }
    }
}
