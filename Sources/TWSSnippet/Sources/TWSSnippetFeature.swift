import Foundation
import ComposableArchitecture
@_spi(Internals) import TWSModels
import TWSCommon
import TWSAPI

@Reducer
public struct TWSSnippetFeature: Sendable {

    @ObservableState
    public struct State: Equatable, Codable, Sendable {

        enum CodingKeys: String, CodingKey {
            case snippet, downloaded, isDownloading, isVisible, customProps
        }

        public var snippet: TWSSnippet
        public var contentDownloaded: Bool = false
        public var isVisible = true
        public var localProps: TWSSnippet.Props = .dictionary([:])
        public var localDynamicResources: [TWSRawDynamicResource] = []
        public var htmlContent: ResourceResponse? = nil
        public var error: APIError? = nil
        
        var isRetry = false
        var isDownloading = false

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
            contentDownloaded = false
            isVisible = true
            isDownloading = false
            localProps = .dictionary([:])
            localDynamicResources = []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(snippet, forKey: .snippet)
            try container.encode(contentDownloaded, forKey: .downloaded)
            try container.encode(isDownloading, forKey: .isDownloading)
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
            case downloadContent
            case cancelDownload
            case downloadCompleted(Result<ResourceResponse, APIError>)
            case setLocalDynamicResources([TWSRawDynamicResource])
        }
        
        @CasePathable
        public enum View {
            case openedTWSView
        }

        @CasePathable
        public enum Delegate {
            case openOverlay(TWSSnippet)
            case reloadProject
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
            return .send(.business(.downloadContent))
                
        case let .business(.snippetUpdated(snippet)):
            state.snippet = snippet
            state.contentDownloaded = false
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
            
        case .business(.setLocalDynamicResources(let dynamicResources)):
            state.localDynamicResources = dynamicResources
            return .none
            
        case .business(.downloadContent):
            guard !state.isDownloading else { return .none }
            state.htmlContent = nil
            state.error = nil
            state.isDownloading = true

            return .run { [api, snippet = state.snippet, localDynamicResources = state.localDynamicResources] send in
                let resources = await downloadAndInjectResources(for: snippet, using: api, localResources: localDynamicResources)
                await send(.business(.downloadCompleted(resources)))
            }.cancellable(id: CancelID.resourceDownload, cancelInFlight: true)

        case .business(.cancelDownload):
            return .cancel(id: CancelID.resourceDownload)
            
        case .business(.downloadCompleted(.success(let resource))):
            logger.info("Resources downloaded succesfully.")
            state.contentDownloaded = true
            state.isDownloading = false
            state.htmlContent = resource
            
            return .none
        case .business(.downloadCompleted(.failure(let error))):
            logger.info("Resource download failed with error: \(error).")
            state.contentDownloaded = true
            state.isDownloading = false
            switch error {
            case .server(let statusCode, _):
                if statusCode == 401 && !state.isRetry {
                    state.isRetry = true
                    return .send(.delegate(.reloadProject))
                }
            default:
                break
            }
            
            state.error = error

            return .none

        case .delegate:
            return .none
        }
    }
    
    enum CancelID {
        case resourceDownload
    }
}
