import Foundation

public struct TWSSnippet: Identifiable, Codable, Hashable {

    public enum SnippetType: Codable {
        case tab
        case popup
        case unknown

        public init(snippetType: String) {
            switch snippetType {
            case "popup", "Popup":
                self = .popup
            case "tab", "Tab":
                self = .tab
            default:
                self = .unknown
            }
        }
    }

    public enum SnippetStatus: String, Codable {
        case enabled
        case disabled
        case unknown

        public init(snippetStatus: String) {
            switch snippetStatus {
            case "Enabled", "enabled":
                self = .enabled
            case "Disabled", "disabled":
                self = .disabled
            default:
                self = .unknown
            }
        }
    }

    public let id: UUID
    public let type: String
    public let status: String
    public var target: URL
    public let visibility: SnippetVisibility?
    @_spi(InternalLibraries) @LossyCodableList public var dynamicResources: [Attachment]?

    public init(
        id: UUID,
        target: URL,
        dynamicResources: [Attachment]? = nil,
        type: String,
        status: String,
        visibilty: SnippetVisibility?
    ) {
        self.id = id
        self.target = target
        self.type = type // SnippetType(snippetType: type)
        self.status = status // SnippetStatus(snippetStatus: status)
        self._dynamicResources = .init(elements: dynamicResources)
        self.visibility = visibilty
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
        hasher.combine(status)
        hasher.combine(target)
        hasher.combine(visibility)
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

    struct SnippetVisibility: Codable, Hashable {
        public let fromUtc: Date?
        public let untilUtc: Date?
    }
}

public extension TWSSnippet.Attachment {

    enum `Type`: String, Codable, Hashable {

        case javascript = "text/javascript"
        case css = "text/css"
    }
}
