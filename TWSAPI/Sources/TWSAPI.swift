import Foundation
import TWSModels

public struct TWSAPI {

    public let getProject: @Sendable (TWSConfiguration) async throws(APIError) -> TWSProject
    public var getSnippetBySharedId: @Sendable (
        TWSConfiguration,
        _ token: String
    ) async throws(APIError) -> TWSSharedSnippet

    static func live(
        host: String
    ) -> Self {
        .init(
            getProject: { configuration throws(APIError) in
                // Need to transform to lowercased, otherwise server returns 404
                let organizationID = configuration.organizationID.uuidString.lowercased()
                let projectID = configuration.projectID.uuidString.lowercased()
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
                    return try JSONDecoder().decode(TWSProject.self, from: result.data)
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
            }
        )
    }
}
