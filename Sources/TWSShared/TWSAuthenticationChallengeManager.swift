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
    
    private var latestCredential: URLCredential? = nil
    private var pendingContinuation: CheckedContinuation<URLCredential?, Never>? = nil

    private init() {}

    public func awaitCredentials(challenge: URLAuthenticationChallenge) async -> URLCredential? {
        pendingContinuation?.resume(returning: nil)
        pendingContinuation = nil
        if challenge.previousFailureCount > 0 {
            latestCredential = nil
        }
        
        if challenge.previousFailureCount == 0 {
            if let credential = latestCredential {
                return credential
            }
        }
        prompt = challenge.protectionSpace.host
        
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
        pendingContinuation = nil
        isPresentingSignIn = false
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
}
