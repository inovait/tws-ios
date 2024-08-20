import Foundation

public struct TWSSnippet: Identifiable, Codable, Equatable {

    public let id: UUID
    public var target: URL
    public var injectUrl: [Attachment]?

    public init(id: UUID, target: URL, injectUrl: [Attachment]? = nil) {
        self.id = id
        self.target = target
        self.injectUrl = injectUrl
    }
}

public extension TWSSnippet {

    struct Attachment: Codable, Equatable {

        public let url: URL
        public let type: `Type`

        public init(url: URL, type: `Type`) {
            self.url = url
            self.type = type
        }
    }
}

public extension TWSSnippet.Attachment {

    enum `Type`: Codable, Equatable {
        case javascript, css
    }
}
