import Foundation

public struct TWSSnippet: Identifiable, Codable, Equatable {

    public let id: UUID
    public var target: URL
    @LossyCodableList public var dynamicResources: [Attachment]?

    public init(id: UUID, target: URL, dynamicResources: [Attachment]? = nil) {
        self.id = id
        self.target = target
        self._dynamicResources = .init(elements: dynamicResources)
    }
}

public extension TWSSnippet {

    struct Attachment: Codable, Equatable {

        public let url: URL
        public let contentType: `Type`

        public init(url: URL, contentType: `Type`) {
            self.url = url
            self.contentType = contentType
        }
    }
}

public extension TWSSnippet.Attachment {

    enum `Type`: String, Codable, Equatable {

        case javascript = "text/javascript"
        case css = "text/css"
    }
}
