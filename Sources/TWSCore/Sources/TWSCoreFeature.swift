import Foundation
import ComposableArchitecture
import TWSSettings
import TWSSnippets
import TWSModels

@Reducer
public struct TWSCoreFeature {

    @ObservableState
    public struct State {

        public var settings: TWSSettingsFeature.State
        public var snippets: TWSSnippetsFeature.State

        public init(
            settings: TWSSettingsFeature.State,
            snippets: TWSSnippetsFeature.State
        ) {
            self.settings = settings
            self.snippets = snippets
        }
    }

    public init() { }

    @CasePathable
    public enum Action {
        case settings(TWSSettingsFeature.Action)
        case snippets(TWSSnippetsFeature.Action)
        case snippetsDidChange
        case stateChanged
        case openOverlay(TWSSnippet)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .snippets(.delegate(.openOverlay(let snippet))):
                @Dependency(\.configuration) var config
                
                return .send(.openOverlay(snippet))
            default:
                return .none
            }
        }
        
        Scope(state: \.settings, action: \.settings) {
            TWSSettingsFeature()
        }
        
        Scope(state: \.snippets, action: \.snippets) {
            TWSSnippetsObserverFeature()
        }
    }
}
