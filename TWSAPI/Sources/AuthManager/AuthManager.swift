//
//  AuthManager.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 25. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

actor AuthManager {

    private let loginUrl: String
    private let registerUrl: String

    private let keychainHelper = KeychainHelper()
    private let accessTokenKey = "TWSAccessToken"
    private let refreshTokenKey = "TWSRefreshToken"
    private let JWTTokenKey = "TWSJWTToken"

    init() {
        if let twsServiceUrls = fetchLoginAndRegisterUrls() {
            loginUrl = twsServiceUrls.0
            registerUrl = twsServiceUrls.1
        } else {
            logger.err("Unable to connect with the server. Check your tws-service.json.")
            loginUrl = ""
            registerUrl = ""
        }
    }

    func forceRefreshTokens() async throws {
        _ = try await getAccessToken(true)
    }

    func getAccessToken(_ force: Bool) async throws -> String {
        if !force {
            if let savedAccessToken = keychainHelper.get(for: accessTokenKey) {
                return savedAccessToken
            }
        }

        let refreshToken = try await getRefreshToken(force)
        let accessToken = try await requestAccessToken(refreshToken)
        keychainHelper.save(accessToken, for: accessTokenKey)
        return accessToken
    }

    private func getRefreshToken(_ force: Bool) async throws -> String {
        if !force {
            if let savedRefreshToken = keychainHelper.get(for: refreshTokenKey) {
                return savedRefreshToken
            }
        }

        let jwtToken = getJWTToken(force)
        let refreshToken = try await requestRefreshToken(jwtToken)
        keychainHelper.save(refreshToken, for: refreshTokenKey)
        return refreshToken
    }
    
    private func getJWTToken(_ force: Bool) -> String {
        if !force {
            if let savedJWTToken = keychainHelper.get(for: JWTTokenKey) {
                return savedJWTToken
            }
        }

        let jwtToken = generateMainJWTToken()
        keychainHelper.save(jwtToken, for: JWTTokenKey)
        return jwtToken
    }

    private func requestAccessToken(_ refreshToken: String) async throws -> String {
        var tokenRequest = URLRequest(url: URL(string: loginUrl)!, timeoutInterval: 60)
        tokenRequest.httpMethod = Request.Method.post.rawValue.uppercased()
        tokenRequest.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        tokenRequest.setValue("text/plain", forHTTPHeaderField: "accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: tokenRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Received a response without being an HTTPURLResponse?")
            }

            if 200..<300 ~= httpResponse.statusCode {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["authToken"] as? String {
                    return accessToken
                } else {
                    throw APIError.auth("Invalid JSON structure or missing 'accessToken'")
                }
            } else {
                logger.err(String(data: data, encoding: .utf8) ?? "null")
                throw APIError.server(httpResponse.statusCode, data)
            }
        } catch {
            throw APIError.local(error)
        }
    }

    private func requestRefreshToken(_ jwtToken: String) async throws -> String {
        var tokenRequest = URLRequest(url: URL(string: registerUrl)!, timeoutInterval: 60)
        tokenRequest.httpMethod = Request.Method.post.rawValue.uppercased()
        tokenRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        tokenRequest.setValue("text/plain", forHTTPHeaderField: "accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: tokenRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Received a response without being an HTTPURLResponse?")
            }

            if 200..<300 ~= httpResponse.statusCode {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let refreshToken = json["refreshToken"] as? String {
                    return refreshToken
                } else {
                    throw APIError.auth("Invalid JSON structure or missing 'refreshToken'")
                }
            } else {
                logger.err(String(data: data, encoding: .utf8) ?? "null")
                throw APIError.server(httpResponse.statusCode, data)
            }
        } catch {
            throw APIError.local(error)
        }
    }
}
