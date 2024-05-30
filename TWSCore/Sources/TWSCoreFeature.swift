import Foundation
import ComposableArchitecture
import TWSSettings
import TWSSnippets

@Reducer
public struct TWSCoreFeature {

    @ObservableState
    public struct State {

        public var settings: TWSSettingsFeature.State
        public var snippets: TWSSnippetsFeature.State

        public init(settings: TWSSettingsFeature.State, snippets: TWSSnippetsFeature.State) {
            self.settings = settings
            self.snippets = snippets
        }
    }

    public init() { }

    public enum Action {
        case settings(TWSSettingsFeature.Action)
        case snippets(TWSSnippetsFeature.Action)
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.settings, action: \.settings) {
            TWSSettingsFeature()
        }

        Scope(state: \.snippets, action: \.snippets) {
            TWSSnippetsFeature()
        }
    }
}
