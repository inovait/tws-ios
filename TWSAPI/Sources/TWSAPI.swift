import Foundation
import TWSModels

public struct TWSAPI {

    private static let _tmpAPIKey = "8281fd90d96b862ba9d76583007ec4b89691b39884a01aa90da5cbb3ad365690"

    public let getSnippets: @Sendable () async throws -> [TWSSnippet]
    public let getSocket: @Sendable () async throws -> URL
    public var getSnippetById: @Sendable (_ snippetId: UUID) async throws -> TWSSnippet

    static func live(
        host: String
    ) -> Self {
        .init(
            getSnippets: {
                let result = try await Router.make(request: .init(
                    method: .get,
                    path: "/organizations/register",
                    host: host,
                    queryItems: [
                        .init(name: "apiKey", value: Self._tmpAPIKey)
                    ]
                ))

                return try JSONDecoder().decode([TWSSnippet].self, from: result.data)
            },
            getSocket: {
                let result = try await Router.make(request: .init(
                    method: .post,
                    path: "/negotiate",
                    host: host,
                    queryItems: [
                        .init(name: "apiKey", value: TWSAPI._tmpAPIKey),
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
            getSnippetById: { snippetId in
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
