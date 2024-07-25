import Foundation
import ComposableArchitecture
import TWSSettings
import TWSSnippets
import TWSUniversalLinks

@Reducer
public struct TWSCoreFeature {

    @ObservableState
    public struct State {

        public var settings: TWSSettingsFeature.State
        public var snippets: TWSSnippetsFeature.State
        public var universalLinks: TWSUniversalLinksFeature.State

        public init(
            settings: TWSSettingsFeature.State,
            snippets: TWSSnippetsFeature.State,
            universalLinks: TWSUniversalLinksFeature.State) {
            self.settings = settings
            self.snippets = snippets
            self.universalLinks = universalLinks
        }
    }

    public init() { }

    public enum Action {
        case settings(TWSSettingsFeature.Action)
        case snippets(TWSSnippetsFeature.Action)
        case universalLinks(TWSUniversalLinksFeature.Action)
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.settings, action: \.settings) {
            TWSSettingsFeature()
        }

        Scope(state: \.snippets, action: \.snippets) {
            TWSSnippetsObserverFeature()
        }

        Scope(state: \.universalLinks, action: \.universalLinks) {
            TWSUniversalLinksFeature()
        }
    }
}
