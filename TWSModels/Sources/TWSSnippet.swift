import Foundation

public struct TWSSnippet: Identifiable, Codable, Hashable, Sendable {

    public enum Engine: ExpressibleByStringLiteral, Hashable, Codable, Sendable {

        case mustache
        case none
        case other(String)

        public init(stringLiteral value: String) {
            let value = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            switch value {
            case "mustache":
                self = .mustache

            case "none":
                self = .none

            default:
                self = .other(value)
            }
        }

        public var rawValue: String {
            switch self {
            case .mustache: "mustache"
            case .none: "none"
            case .other(let string): string
            }
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = .init(stringLiteral: value)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    public let id: String
    public var target: URL
    @_spi(Internals) public let visibility: SnippetVisibility?
    public var props: Props?
    public var engine: Engine?
    public let headers: [String: String]?
    @_spi(Internals) @LossyCodableList public var dynamicResources: [Attachment]?

    private init(
        id: String,
        target: URL,
        visibility: SnippetVisibility?,
        props: Props,
        engine: Engine?,
        headers: [String: String]?,
        dynamicResources: [Attachment]?
    ) {
        self.id = id
        self.target = target
        self.visibility = visibility
        self.props = props
        self.engine = engine
        self.headers = headers
        self._dynamicResources = .init(elements: dynamicResources)
    }

    @_spi(Internals)
    public init(
        id: String,
        target: URL,
        dynamicResources: [Attachment]? = nil,
        visibility: SnippetVisibility? = nil,
        props: Props = .dictionary([:]),
        engine: Engine? = nil,
        headers: [String: String]? = nil
    ) {
        self.init(
            id: id,
            target: target,
            visibility: visibility,
            props: props,
            engine: engine,
            headers: headers,
            dynamicResources: dynamicResources
        )
    }

    public init(
        id: String,
        target: URL,
        props: Props = .dictionary([:]),
        engine: Engine? = nil,
        headers: [String: String]? = nil
    ) {
        self.init(
            id: id,
            target: target,
            visibility: nil,
            props: props,
            engine: engine,
            headers: headers,
            dynamicResources: nil
        )
    }
}

public extension TWSSnippet {

    struct Attachment: Codable, Hashable, Sendable {

        public let url: URL
        public let contentType: `Type`

        public init(url: URL, contentType: `Type`) {
            self.url = url
            self.contentType = contentType
        }
    }

    struct SnippetVisibility: Codable, Hashable, Sendable {
        public let fromUtc: Date?
        public let untilUtc: Date?
    }
}

public extension TWSSnippet.Attachment {

    enum `Type`: String, Codable, Hashable, Sendable {

        case javascript = "text/javascript"
        case css = "text/css"
        @_spi(Internals) case html = "text/html"
    }
}
