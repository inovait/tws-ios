import Foundation
import TWSModels

public struct TWSAPI {

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
                    path: "/snippets/register",
                    host: host,
                    queryItems: [
                        .init(name: "apiKey", value: "true")
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
                        .init(name: "apiKey", value: "true")
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
                    path: "/snippets/\(snippetId.uuidString)",
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
