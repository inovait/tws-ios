//
//  TWSAuthenticationChallengeManager.swift
//  TWS
//
//  Created by Sven Kotnik on 23. 4. 26.
//

import Foundation
import Combine
import Security

@MainActor
public final class TWSAuthenticationChallengeManager: ObservableObject {
    public static let shared = TWSAuthenticationChallengeManager()
    
    @Published public var isPresentingSignIn: Bool = false
    @Published public var prompt: String = ""
    @Published public var username: String = ""
    @Published public var password: String = ""
    private var host: String = ""
    private var realm: String? = nil
    
    private var latestCredential: URLCredential? = nil
    private var pendingContinuation: CheckedContinuation<URLCredential?, Never>? = nil

    private init() {}

    public func awaitCredentials(challenge: URLAuthenticationChallenge) async -> URLCredential? {
        pendingContinuation?.resume(returning: nil)
        pendingContinuation = nil

        let protectionSpace = challenge.protectionSpace
        let key = KeychainCredentialStore.Key(
            host: protectionSpace.host,
            realm: protectionSpace.realm
        )

        if challenge.previousFailureCount > 0 {
            latestCredential = nil
            KeychainCredentialStore.delete(for: key)
        }

        if challenge.previousFailureCount == 0 {
            if let credential = latestCredential {
                return credential
            }

            if let storedCredential = KeychainCredentialStore.read(for: key) {
                latestCredential = storedCredential
                return storedCredential
            }
        }
        host = protectionSpace.host
        realm = protectionSpace.realm
        prompt = protectionSpace.host
        username = ""
        password = ""
        isPresentingSignIn = true

        return await withCheckedContinuation { (continuation: CheckedContinuation<URLCredential?, Never>) in
            self.pendingContinuation = continuation
        }
    }

    public func submit() {
        guard let continuation = pendingContinuation else { return }
        
        let creds = URLCredential(user: username, password: password, persistence: .forSession)
        latestCredential = creds

        let key = KeychainCredentialStore.Key(host: host, realm: realm)
        KeychainCredentialStore.save(creds, for: key)

        resetState()
        continuation.resume(returning: creds)
    }

    public func cancel() {
        pendingContinuation?.resume(returning: nil)
        pendingContinuation = nil
        isPresentingSignIn = false
    }

    public func prefillAndSubmit(username: String, password: String) {
        self.username = username
        self.password = password
        submit()
    }
    
    public static func basicAuthFlowHandler(
        challenge: URLAuthenticationChallenge,
        pendingAuthChallenge: @escaping @MainActor @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        Task {
            let cred = await TWSAuthenticationChallengeManager.shared.awaitCredentials(challenge: challenge)
            if let cred {
                pendingAuthChallenge(.useCredential, cred)
            } else {
                pendingAuthChallenge(.cancelAuthenticationChallenge, nil)
            }
        }
    }
    
    private func resetState() {
        self.isPresentingSignIn = false
        self.pendingContinuation = nil
        self.password = ""
        self.username = ""
        self.prompt = ""
        self.host = ""
        self.realm = nil
    }
}

// MARK: - Keychain

private final class KeychainCredentialStore {
    struct Key: Hashable {
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

    private init() {}

    static func save(_ credential: URLCredential, for key: Key) {
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

        let status = SecItemAdd(query as CFDictionary, nil)
    }

    static func read(for key: Key) -> URLCredential? {
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

    static func delete(for key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service
        ]

        SecItemDelete(query as CFDictionary)
    }
}
