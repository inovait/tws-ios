import Foundation
import ComposableArchitecture
import TWSModels

@Reducer
public struct TWSSnippetFeature {

    @ObservableState
    public struct State: Equatable {

        public let snippet: TWSSnippet

        public init(snippet: TWSSnippet) {
            self.snippet = snippet
        }
    }

    public enum Action { }

    public init() { }
}
