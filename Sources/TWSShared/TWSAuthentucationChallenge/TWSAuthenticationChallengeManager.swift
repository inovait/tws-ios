//
//  TWSAuthenticationChallengeManager.swift
//  TWS
//
//  Created by Sven Kotnik on 23. 4. 26.
//

import Foundation
import Combine

@MainActor
public final class TWSAuthenticationChallengeManager: ObservableObject {
    public static let shared = TWSAuthenticationChallengeManager()
    
    @Published public var isPresentingSignIn: Bool = false
    @Published public var prompt: String = ""
    @Published public var username: String = ""
    @Published public var password: String = ""
    private var host: String = ""
    private var realm: String? = nil
    
    private var persistanceStore: CredentialStore
    private var latestCredential: URLCredential? = nil
    private var pendingContinuation: CheckedContinuation<URLCredential?, Never>? = nil

    private init() {
        switch TWSConfig.getBasicAuthPersistence() {
        case .keychain:
            self.persistanceStore = KeychainCredentialStore()
        case .session:
            self.persistanceStore = SessionCredentialStore()
        }
    }

    public func awaitCredentials(challenge: URLAuthenticationChallenge) async -> URLCredential? {
        pendingContinuation?.resume(returning: nil)
        pendingContinuation = nil

        let protectionSpace = challenge.protectionSpace
        

        let key = CredentialsKey(
            host: protectionSpace.host,
            realm: protectionSpace.realm
        )
            
        if challenge.previousFailureCount > 0 {
            latestCredential = nil
            
            persistanceStore.delete(for: key)
        }
        
        if challenge.previousFailureCount == 0 {
            if let credential = latestCredential {
                return credential
            }
            
            if let storedCredential = persistanceStore.read(for: key) {
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

        
        let key = CredentialsKey(host: host, realm: realm)
        persistanceStore.save(creds, for: key)
        

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
