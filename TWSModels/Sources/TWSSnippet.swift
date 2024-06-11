import Foundation

public struct TWSSnippet: Identifiable, Codable, Equatable {

    public let id: UUID
    public var target: URL

    public init(id: UUID, target: URL) {
        self.id = id
        self.target = target
    }
}
