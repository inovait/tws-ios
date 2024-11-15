import Foundation
import TWSModels
import TWSFormatters

public struct TWSAPI {

    public let getProject: @Sendable (
        TWSConfiguration
    ) async throws(APIError) -> (TWSProject, Date?)

    public var getSnippetBySharedId: @Sendable (
        TWSConfiguration,
        _ token: String
    ) async throws(APIError) -> TWSSharedSnippet

    public let getResource: @Sendable (
        TWSSnippet.Attachment, [String: String]
    ) async throws(APIError) -> String

    static func live(
        host: String
    ) -> Self {
        .init(
            getProject: { configuration throws(APIError) in
                // Need to transform to lowercased, otherwise server returns 404
                let organizationID = configuration.organizationID
                let projectID = configuration.projectID
                let result = try await Router.make(request: .init(
                        method: .get,
                        path: "/organizations/\(organizationID)/projects/\(projectID)/register",
                        host: host,
                        queryItems: [
                            .init(name: "apiKey", value: "abc123")
                        ],
                        headers: [:]
                    ))

                do {
                    let decoder = JSONDecoder()

                    decoder.dateDecodingStrategy = isoDateDecoder

                    return (try decoder.decode(TWSProject.self, from: result.data), result.dateOfResponse)
                } catch {
                    throw APIError.decode(error)
                }
            },
            getSnippetBySharedId: { _, token throws(APIError) in
                let result = try await Router.make(request: .init(
                    method: .get,
                    path: "/shared/\(token)",
                    host: host,
                    queryItems: [
                        .init(name: "apiKey", value: "abc123")
                    ],
                    headers: [
                        "Accept": "application/json"
                    ]
                ))

                do {
                    return try JSONDecoder().decode(TWSSharedSnippet.self, from: result.data)
                } catch {
                    throw APIError.decode(error)
                }
            },
            getResource: { attachment, headers throws(APIError) in
                let result = try await Router.make(request: .init(
                    method: .get,
                    path: attachment.url.path(),
                    host: attachment.url.host() ?? "",
                    queryItems: [],
                    headers: headers
                ))

                if let payload = String(data: result.data, encoding: .utf8) {
                    return payload
                }

                throw .decode(NSError(domain: "invalid-string", code: -1))
            }
        )
    }
}
