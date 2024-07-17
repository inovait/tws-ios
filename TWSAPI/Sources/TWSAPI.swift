import Foundation
import TWSModels

public struct TWSAPI {

    public let getSnippets: @Sendable (TWSConfiguration) async throws -> [TWSSnippet]
    public let getSocket: @Sendable (TWSConfiguration) async throws -> URL
    public var getSnippetById: @Sendable (TWSConfiguration, _ snippetId: UUID) async throws -> TWSSnippet

    static func live(
        host: String
    ) -> Self {
        .init(
            getSnippets: { configuration in
                let result = try await Router.make(request: .init(
                    method: .get,
                    path: "/organizations/register",
                    host: host,
                    queryItems: [
                        .init(name: "apiKey", value: configuration.organizationID)
                    ]
                ))

                return try JSONDecoder().decode([TWSSnippet].self, from: result.data)
            },
            getSocket: { configuration in
                let result = try await Router.make(request: .init(
                    method: .post,
                    path: "/negotiate",
                    host: host,
                    queryItems: [
                        .init(name: "apiKey", value: configuration.organizationID),
                        .init(name: "userId", value: "abc123")
                    ]
                ))

                let urlStr = String(decoding: result.data, as: UTF8.self)

                guard let url = URL(string: urlStr)
                else {
                    throw APIError.local(NSError(domain: "invalidSocketUrl", code: 0))
                }

                return url
            },
            getSnippetById: { _, snippetId in
                let result = try await Router.make(request: .init(
                    method: .get,
                    path: "organizations/snippets/\(snippetId.uuidString)",
                    host: host,
                    queryItems: [
                        .init(name: "apiKey", value: "true")
                    ]
                ))

                return try JSONDecoder().decode(TWSSnippet.self, from: result.data)
            }
        )
    }
}
