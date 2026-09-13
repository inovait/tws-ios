//
//  SessionCredentialStore.swift
//  TWS
//
//  Created by Sven Kotnik on 4. 5. 26.
//

import Foundation

final class SessionCredentialStore: CredentialStore {
    private var credentials: [CredentialsKey: URLCredential] = [:]

    init() {}

    func save(_ credential: URLCredential, for key: CredentialsKey) {
        credentials[key] = URLCredential(
            user: credential.user ?? "",
            password: credential.password ?? "",
            persistence: .forSession
        )
    }

    func read(for key: CredentialsKey) -> URLCredential? {
        credentials[key]
    }

    func delete(for key: CredentialsKey) {
        credentials.removeValue(forKey: key)
    }
}
