////
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


import XCTest
import Foundation
@_spi(Internals) internal import TWSShared

@MainActor
final class TWSAuthenticationChallengeManagerTests: XCTestCase {

    private final class MockCredentialStore: CredentialStore {
        var storage: [CredentialsKey: URLCredential] = [:]
        var deletedKeys: [CredentialsKey] = []

        func read(for key: CredentialsKey) -> URLCredential? {
            storage[key]
        }

        func save(_ credential: URLCredential, for key: CredentialsKey) {
            storage[key] = credential
        }

        func delete(for key: CredentialsKey) {
            deletedKeys.append(key)
            storage[key] = nil
        }
    }
    
    private final class MockURLAuthChallengeSender: NSObject, URLAuthenticationChallengeSender {
        func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
        
        func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
        
        func cancel(_ challenge: URLAuthenticationChallenge) {}
    }

    private func makeChallenge(
        host: String = "example.com",
        realm: String? = "Restricted",
        previousFailureCount: Int = 0
    ) -> URLAuthenticationChallenge {
        let protectionSpace = URLProtectionSpace(
            host: host,
            port: 443,
            protocol: NSURLProtectionSpaceHTTPS,
            realm: realm,
            authenticationMethod: NSURLAuthenticationMethodHTTPBasic
        )

        return URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: previousFailureCount,
            failureResponse: nil,
            error: nil,
            sender: MockURLAuthChallengeSender()
        )
    }

    func testAwaitCredentialsReturnsStoredCredentialWhenAvailable() async {
        let store = MockCredentialStore()
        let manager = TWSAuthenticationChallengeManager(persistanceStore: store)

        let key = CredentialsKey(host: "example.com", realm: "Restricted")
        let stored = URLCredential(user: "test", password: "secret", persistence: .forSession)
        store.storage[key] = stored

        let credential = await manager.awaitCredentials(challenge: makeChallenge())

        XCTAssertEqual(credential?.user, "test")
        XCTAssertEqual(credential?.password, "secret")
        XCTAssertFalse(manager.isPresentingSignIn)
    }

    func testAwaitCredentialsPresentsSignInWhenNoStoredCredentialExists() async {
        let store = MockCredentialStore()
        let manager = TWSAuthenticationChallengeManager(persistanceStore: store)

        let task = Task {
            await manager.awaitCredentials(challenge: makeChallenge())
        }

        await Task.yield()

        XCTAssertTrue(manager.isPresentingSignIn)
        XCTAssertEqual(manager.prompt, "example.com")
        XCTAssertEqual(manager.username, "")
        XCTAssertEqual(manager.password, "")

        manager.cancel()
        _ = await task.value
    }

    func testSubmitReturnsCredentialAndSavesIt() async {
        let store = MockCredentialStore()
        let manager = TWSAuthenticationChallengeManager(persistanceStore: store)

        let task = Task {
            await manager.awaitCredentials(challenge: makeChallenge())
        }

        await Task.yield()

        manager.username = "test"
        manager.password = "secret"
        manager.submit()

        let credential = await task.value

        XCTAssertEqual(credential?.user, "test")
        XCTAssertEqual(credential?.password, "secret")
        XCTAssertFalse(manager.isPresentingSignIn)

        let key = CredentialsKey(host: "example.com", realm: "Restricted")
        XCTAssertEqual(store.storage[key]?.user, "test")
        XCTAssertEqual(store.storage[key]?.password, "secret")
    }

    func testCancelReturnsNilAndDismissesSignIn() async {
        let store = MockCredentialStore()
        let manager = TWSAuthenticationChallengeManager(persistanceStore: store)

        let task = Task {
            await manager.awaitCredentials(challenge: makeChallenge())
        }

        await Task.yield()

        manager.cancel()

        let credential = await task.value

        XCTAssertNil(credential)
        XCTAssertFalse(manager.isPresentingSignIn)
    }

    func testPreviousFailureDeletesStoredCredentialAndPromptsAgain() async {
        let store = MockCredentialStore()
        let manager = TWSAuthenticationChallengeManager(persistanceStore: store)

        let key = CredentialsKey(host: "example.com", realm: "Restricted")
        store.storage[key] = URLCredential(user: "bad", password: "bad", persistence: .forSession)

        let task = Task {
            await manager.awaitCredentials(
                challenge: makeChallenge(previousFailureCount: 1)
            )
        }

        await Task.yield()

        XCTAssertTrue(store.deletedKeys.contains(key))
        XCTAssertTrue(manager.isPresentingSignIn)

        manager.cancel()
        let result = await task.value
        XCTAssertNil(result)
    }

    func testPrefillAndSubmitSubmitsCredential() async {
        let store = MockCredentialStore()
        let manager = TWSAuthenticationChallengeManager(persistanceStore: store)

        let task = Task {
            await manager.awaitCredentials(challenge: makeChallenge())
        }

        await Task.yield()

        manager.prefillAndSubmit(username: "test", password: "secret")

        let credential = await task.value

        XCTAssertEqual(credential?.user, "test")
        XCTAssertEqual(credential?.password, "secret")
        XCTAssertFalse(manager.isPresentingSignIn)
    }
}
