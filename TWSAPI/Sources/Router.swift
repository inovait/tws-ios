//
//  Router.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

class Router {

    class func make(request: Request) async throws -> APIResult {
        var components = URLComponents()
        components.scheme = "https"
        components.host = request.host
        components.path = request.path

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            fatalError("Failed to create an URL")
        }

        var urlRequest = URLRequest(url: url, timeoutInterval: 60)
        urlRequest.httpMethod = request.method.rawValue.uppercased()

        do {
            let result = try await URLSession.shared.data(for: urlRequest)
            guard
                let httpResult = result.1 as? HTTPURLResponse
            else {
                fatalError("Received a response without being an HTTPURLResponse?")
            }

            if 200..<300 ~= httpResult.statusCode {
                return .init(
                    statusCode: httpResult.statusCode,
                    data: result.0
                )
            } else {
                throw APIError.server(httpResult.statusCode, result.0)
            }
        } catch {
            throw APIError.local(error)
        }
    }
}

struct APIResult {

    let statusCode: Int
    let data: Data
}

public enum APIError: Error {

    case local(Error)
    case server(Int, Data)
}
