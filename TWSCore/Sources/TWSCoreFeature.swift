import Foundation
import ComposableArchitecture
import TWSSettings
import TWSSnippet

@Reducer
public struct TWSCoreFeature {

    @ObservableState
    public struct State {

        public var settings: TWSSettingsFeature.State
        public var snippet: TWSSnippetFeature.State

        public init(settings: TWSSettingsFeature.State, snippet: TWSSnippetFeature.State) {
            self.settings = settings
            self.snippet = snippet
        }
    }

    public init() { }

    public enum Action {
        case settings(TWSSettingsFeature.Action)
        case snippet(TWSSnippetFeature.Action)
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.settings, action: \.settings) {
            TWSSettingsFeature()
        }

        Scope(state: \.snippet, action: \.snippet) {
            TWSSnippetFeature()
        }
    }
}
