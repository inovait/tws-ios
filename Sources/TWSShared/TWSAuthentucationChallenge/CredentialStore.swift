//
//  CredentialStore.swift
//  TWS
//
//  Created by Sven Kotnik on 4. 5. 26.
//

import Foundation

@MainActor
protocol CredentialStore {

    func save(_ credential: URLCredential, for key: CredentialsKey)
    func read(for key: CredentialsKey) -> URLCredential?
    func delete(for key: CredentialsKey)
}
