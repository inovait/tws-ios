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

func fetchLoginAndRegisterUrls() -> (String, String)? {
    let frameworkBundle = Bundle(for: Router.self)
    guard let jsonFilePath = frameworkBundle.url(forResource: "tws-service", withExtension: "json") else {
        logger.err("Unable to locate tws-service.json in the project directory.")
        return nil
    }

    do {
        let jsonData = try Data(contentsOf: jsonFilePath)
        guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: String],
              let loginUrl = jsonDict["login_uri"],
              let registerUrl = jsonDict["register_uri"]
        else {
            logger.err("The tws-service.json is present, but it's form is corrupted.")
            return nil
        }
        return (loginUrl, registerUrl)
    } catch {
        logger.err("The tws-service.json is present, but it's form is corrupted.")
        return nil
    }
}

func generateMainJWTToken() -> String {
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
        logger.err("JWT signing failed")
        return ""
    }
    let jwtSigner = JWTSigner.rs256(privateKey: privateKey)
    if let signedJWT = try? jwt.sign(using: jwtSigner) {
        return signedJWT
    }
    logger.err("Failed to sign the JWT")
    return ""
}

private func getJWTData() -> JWTData? {
    let frameworkBundle = Bundle(for: Router.self)
    guard let jsonFilePath = frameworkBundle.url(forResource: "tws-service", withExtension: "json") else {
        logger.err("Unable to locate tws-service.json in the project directory.")
        return nil
    }

    do {
        let jsonData = try Data(contentsOf: jsonFilePath)
        guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: String],
              let secret = jsonDict["private_key"],
              let privateKeyId = jsonDict["private_key_id"],
              let clientId = jsonDict["client_id"]
        else {
            logger.err("The tws-service.json is present, but it's form is corrupted.")
            return nil
        }
        return JWTData(
            secret: secret,
            privateKeyId: privateKeyId,
            clientId: clientId
        )
    } catch {
        logger.err("The tws-service.json is present, but it's form is corrupted.")
        return nil
    }
}
