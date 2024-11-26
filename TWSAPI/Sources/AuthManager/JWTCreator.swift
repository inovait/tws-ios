//
//  JWTCreator.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 21. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import SwiftJWT
import Foundation

private struct JWTData {
    let secret: String
    let privateKeyId: String
    let clientId: String
}

// periphery:ignore
private struct Payload: Claims {
    let exp: String
    let iss: String
    // swiftlint:disable identifier_name
    let client_id: String
    // swiftlint:enable identifier_name
}

struct JWTCreator {

    static func fetchLoginAndRegisterUrls() -> (String, String)? {
        guard let jsonFilePath = Bundle.main.path(forResource: "tws-service", ofType: "json") else {
            fatalError("Unable to locate tws-service.json in the project directory.")
        }

        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonFilePath))
            guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                  let loginUrl = jsonDict["login_uri"],
                  let registerUrl = jsonDict["register_uri"]
            else {
                fatalError("The tws-service.json is present, but it's form is corrupted.")
            }
            return (loginUrl, registerUrl)
        } catch {
            fatalError("The tws-service.json is present, but it's form is corrupted.")
        }
    }

    static func generateMainJWTToken() -> String {
        guard let jwtData = getJWTData() else {
            return ""
        }

        let header = Header(kid: jwtData.privateKeyId)
        let payload = Payload(
            exp: "211100000000",
            iss: jwtData.clientId,
            client_id: jwtData.clientId
        )

        var jwt = JWT(header: header, claims: payload)

        guard let privateKey = jwtData.secret.data(using: .utf8) else {
            fatalError("JWT signing failed")
        }
        let jwtSigner = JWTSigner.rs256(privateKey: privateKey)
        if let signedJWT = try? jwt.sign(using: jwtSigner) {
            return signedJWT
        }
        fatalError("Failed to sign the JWT")
    }
}

private func getJWTData() -> JWTData? {
    guard let jsonFilePath = Bundle.main.path(forResource: "tws-service", ofType: "json") else {
        fatalError("Unable to locate tws-service.json in the project directory.")
    }

    do {
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonFilePath))
        guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: String],
              let secret = jsonDict["private_key"],
              let privateKeyId = jsonDict["private_key_id"],
              let clientId = jsonDict["client_id"]
        else {
            fatalError("The tws-service.json is present, but it's form is corrupted.")
        }
        return JWTData(
            secret: secret,
            privateKeyId: privateKeyId,
            clientId: clientId
        )
    } catch {
        fatalError("The tws-service.json is present, but it's form is corrupted.")
    }
}
