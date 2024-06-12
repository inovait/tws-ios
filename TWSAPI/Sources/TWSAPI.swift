import Foundation
import TWSModels

public struct TWSAPI {

    public let getSnippets: @Sendable () async throws -> [TWSSnippet]
    public let getSocket: @Sendable () async throws -> URL

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
                fatalError()
            }
        )
    }
}
