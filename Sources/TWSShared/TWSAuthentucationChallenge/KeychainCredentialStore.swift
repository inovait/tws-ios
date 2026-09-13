//
//  KeychainCredentialStore.swift
//  TWS
//
//  Created by Sven Kotnik on 4. 5. 26.
//

import Foundation
import Security

final class KeychainCredentialStore: CredentialStore {
    init() {}

    func save(_ credential: URLCredential, for key: CredentialsKey) {
        guard let password = credential.password else { return }

        let passwordData = Data(password.utf8)

        delete(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: credential.user,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func read(for key: CredentialsKey) -> URLCredential? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let result = item as? [String: Any],
              let username = result[kSecAttrAccount as String] as? String,
              let passwordData = result[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: .utf8)
        else {
            return nil
        }

        return URLCredential(user: username, password: password, persistence: .forSession)
    }

    func delete(for key: CredentialsKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service
        ]

        SecItemDelete(query as CFDictionary)
    }
}
