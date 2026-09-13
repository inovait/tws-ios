//
//  CredentialsKey.swift
//  TWS
//
//  Created by Sven Kotnik on 4. 5. 26.
//

@_spi(Internals)
public struct CredentialsKey: Hashable {
    let host: String
    let realm: String?
    
    public init(host: String, realm: String?) {
        self.host = host
        self.realm = realm
    }

    var service: String {
        if let realm, !realm.isEmpty {
            return "TWS.BasicAuth.\(host).\(realm)"
        } else {
            return "TWS.BasicAuth.\(host)"
        }
    }
}
