import Foundation

public struct TWSSnippet: Identifiable, Codable, Hashable {

    public enum SnippetType: String, ExpressibleByStringLiteral, Codable {
        case tab
        case popup
        case unknown

        public init(stringLiteral value: String) {
            if let option = SnippetType(rawValue: value.lowercased()) {
                self = option
            } else {
                self = .unknown
            }
        }
    }

    public enum SnippetStatus: String, ExpressibleByStringLiteral, Codable {
        case enabled
        case disabled
        case unknown

        public init(stringLiteral value: String) {
            if let option = SnippetStatus(rawValue: value.lowercased()) {
                self = option
            } else {
                self = .unknown
            }
        }
    }

    public let id: UUID
    public let type: SnippetType
    public let status: SnippetStatus
    public var target: URL
    @_spi(InternalLibraries) @LossyCodableList public var dynamicResources: [Attachment]?

    public init(
        id: UUID,
        target: URL,
        dynamicResources: [Attachment]? = nil,
        type: SnippetType = .tab,
        status: SnippetStatus = .enabled
    ) {
        self.id = id
        self.target = target
        self.type = type
        self.status = status
        self._dynamicResources = .init(elements: dynamicResources)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
        hasher.combine(status)
        hasher.combine(target)
    }
}

public extension TWSSnippet {

    struct Attachment: Codable, Hashable {

        public let url: URL
        public let contentType: `Type`

        public init(url: URL, contentType: `Type`) {
            self.url = url
            self.contentType = contentType
        }
    }
}

public extension TWSSnippet.Attachment {

    enum `Type`: String, Codable, Hashable {

        case javascript = "text/javascript"
        case css = "text/css"
    }
}
