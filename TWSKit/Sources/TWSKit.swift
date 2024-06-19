import Foundation
import SwiftUI
import TWSModels
@_implementationOnly import TWSCore
@_implementationOnly import ComposableArchitecture

public class TWSManager {

    private(set) var store: StoreOf<TWSCoreFeature>
    public let stream: AsyncStream<[TWSSnippet]>

    init(
        store: StoreOf<TWSCoreFeature>,
        stream: AsyncStream<[TWSSnippet]>
    ) {
        self.store = store
        self.stream = stream
    }

    // MARK: - Public

    public var snippets: [TWSSnippet] {
        precondition(Thread.isMainThread, "`snippets()` can only be called on main thread")
        return store.snippets.snippets.elements.map(\.snippet)
    }

    public func run(listenForChanges: Bool) {
        store.send(.snippets(.business(.load)))

        if listenForChanges {
            store.send(.snippets(.business(.listenForChanges)))

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                self.store.send(.snippets(.business(.stopListeningForChanges)))
            }
        }
    }

    public func set(source: TWSSource) {
        store.send(.snippets(.business(.set(source: source))))
    }

    // MARK: - Internal

    func set(height: CGFloat, for snippet: TWSSnippet, displayID: String) {
        assert(Thread.isMainThread)
        store.send(.snippets(.business(
            .snippets(.element(id: snippet.id, action: .business(.update(height: height, forId: displayID))))
        )))
    }

    func height(for snippet: TWSSnippet, displayID: String) -> CGFloat? {
        assert(Thread.isMainThread)
        let height = store.snippets.snippets[id: snippet.id]?.displayInfo.displays[displayID]?.height
        return height
    }
}
