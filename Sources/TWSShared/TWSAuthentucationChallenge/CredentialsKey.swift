//
//  CredentialsKey.swift
//  TWS
//
//  Created by Sven Kotnik on 4. 5. 26.
//


struct CredentialsKey: Hashable {
        let host: String
        let realm: String?

        var service: String {
            if let realm, !realm.isEmpty {
                return "TWS.BasicAuth.\(host).\(realm)"
            } else {
                return "TWS.BasicAuth.\(host)"
            }
        }

        var account: String {
            host
        }
    }
