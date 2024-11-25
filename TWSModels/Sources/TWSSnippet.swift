import Foundation

/// A struct representing a snippet within the TWS system.
///
/// Each snippet is uniquely identified and contains metadata, resources, and rendering configurations
/// that dictate how the snippet behaves and is displayed.
public struct TWSSnippet: Identifiable, Codable, Hashable, Sendable {

    /// The rendering engine used for the snippet.
    public enum Engine: ExpressibleByStringLiteral, Hashable, Codable, Sendable {

        /// Indicates the Mustache rendering engine.
        case mustache

        /// Indicates no specific rendering engine is used.
        case none

        /// Indicates a custom rendering engine with its name as a `String`.
        case other(String)

        /// Initializes an `Engine` from a string literal.
        /// - Parameter stringLiteral: Raw value
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

        /// The raw value of the rendering engine as a `String`.
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

    /// The unique identifier of the snippet.
    public let id: String

    /// The URL target associated with the snippet.
    ///
    /// This property defines the destination URL for the snippet. If necessary, it can be customized for a specific ``TWSSnippet`` instance within the view.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ForEach(tws.snippets()) { snippet in
    ///     var snippet = snippet
    ///     snippet.target = URL(string: "https://example.com")!
    ///
    ///     return TWSView(snippet: snippet)
    /// }
    /// ```
    ///
    /// In this example, the `target` URL is modified for each snippet before being passed to the ``TWSView``.
    public var target: URL

    /// Visibility constraints for the snippet.
    @_spi(Internals) public let visibility: SnippetVisibility?

    /// Custom properties for the snippet, typically used for [Mustache](https://mustache.github.io/mustache.5.html) rendering.
    ///
    /// This property allows you to define or override the properties for a specific ``TWSSnippet`` instance. These properties can be modified dynamically within the view.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ForEach(tws.snippets()) { snippet in
    ///     var snippet = snippet
    ///     snippet.props = .dictionary([
    ///         "key1": .string("value1"),
    ///         "key2": .int(42)
    ///     ])
    ///
    ///     return TWSView(snippet: snippet)
    /// }
    /// ```
    ///
    /// In this example, the `props` property is customized for each snippet before being passed to the ``TWSView``.
    public var props: Props?

    /// The rendering engine used for this snippet.
    public var engine: Engine?

    /// Headers associated with the snippet.
    public let headers: [String: String]?

    /// Dynamic resources attached to the snippet, such as JavaScript or CSS files.
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

    /// Represents an attachment associated with a snippet, such as a JavaScript or CSS file.
    struct Attachment: Codable, Hashable, Sendable {

        /// The URL of the attachment.
        public let url: URL

        /// The content type of the attachment.
        public let contentType: `Type`

        /// Initializes an `Attachment`.
        ///
        /// - Parameters:
        ///   - url: The URL of the attachment.
        ///   - contentType: The type of content the attachment contains.
        public init(url: URL, contentType: `Type`) {
            self.url = url
            self.contentType = contentType
        }
    }

    /// Visibility constraints for the snippet.
    struct SnippetVisibility: Codable, Hashable, Sendable {

        /// The UTC date and time after which the snippet becomes visible.
        public let fromUtc: Date?

        /// The UTC date and time before which the snippet remains visible.
        public let untilUtc: Date?
    }
}

public extension TWSSnippet.Attachment {

    /// Enum representing the type of content for an attachment.
    ///
    /// This enum defines the content type of an attachment associated with a ``TWSSnippet``. It supports standard MIME types for JavaScript, CSS, and HTML.
    enum `Type`: String, Codable, Hashable, Sendable {

        /// Represents a JavaScript file (`text/javascript`).
        case javascript = "text/javascript"

        /// Represents a CSS file (`text/css`).
        case css = "text/css"

        /// Represents an HTML file (`text/html`).
        ///
        /// > Note: This type is for internal use only.
        @_spi(Internals) case html = "text/html"
    }
}
