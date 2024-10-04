import Foundation
import ComposableArchitecture
import TWSModels

@Reducer
public struct TWSSnippetFeature {

    @ObservableState
    public struct State: Equatable, Codable {

        public var snippet: TWSSnippet
        public var displayInfo: TWSDisplayInfo
        public var updateCount = 0
        public var showIn: DateComponents?
        public var hideIn: DateComponents?

        public init(snippet: TWSSnippet, serverDate: Date? = nil) {
            self.snippet = snippet
            self.displayInfo = .init()
            if let serverDate {
                if let fromDate = snippet.visibility?.fromUtc, fromDate > serverDate {
                    self.showIn = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: serverDate, to: fromDate)
                }
                if let untilDate = snippet.visibility?.untilUtc, untilDate > serverDate {
                    self.hideIn = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: serverDate, to: untilDate)
                }
            }
        }
    }

    public enum Action {

        @CasePathable
        public enum Business {
            case update(height: CGFloat, forId: String)
            case snippetUpdated(snippet: TWSSnippet?)
        }

        case business(Business)
    }

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
            if let snippet, snippet != state.snippet {
                logger.info("Snippet updated from \(state.snippet) to \(snippet).")
                state.snippet = snippet
            } else {
                logger.info("Snippet's payload changed")
                state.updateCount += 1
            }

            return .none
        }
    }
}
