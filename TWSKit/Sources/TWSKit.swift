import Foundation
import SwiftUI
import TWSModels
@_implementationOnly import TWSCore
@_implementationOnly import ComposableArchitecture

// TODO: Switch back to dynamic frameworks
// https://github.com/tuist/tuist/issues/6339

public class TWSManager {

    private let store: StoreOf<TWSCoreFeature>
    public let stream: AsyncStream<[TWSSnippet]>

    init(
        store: StoreOf<TWSCoreFeature>,
        stream: AsyncStream<[TWSSnippet]>
    ) {
        self.store = store
        self.stream = stream
    }

    public func run() {
        store.send(.snippets(.business(.load)))
    }
}
