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

import Testing
import TWS
import TWSNotifications

@MainActor
struct TWSNotificationsTests {
    @Test(
        "Tests parsing of correct notificaiton payload setup",
        arguments: [["type": "snippet_push", "path": "test/snippet"]]
    )
    func notificationCorrectPayloadParsingTest(userInfo: [String: String]) async throws {
        let manager = TWSFactory.new(with: TWSBasicConfiguration(id: "test"))
        manager.registerManager()
        
        #expect(await TWSNotification().handleTWSPushNotification(userInfo))
    }
    
    @Test(
        "Tests parsing of correct notificaiton payload setup",
        arguments: [["type": "snippet_push", "path": "noManager/snippet"]]
    )
    func notificationNoManagerPayloadParsingTest(userInfo: [String: String]) async throws {
        
        #expect(await !TWSNotification().handleTWSPushNotification(userInfo))
    }
    
    @Test(
        "Tests parsing of correct notificaiton payload setup",
        arguments: [["type": "snippet_push", "path": "wrongManager/snippet"]]
    )
    func notificationWrongManagerPayloadParsingTest(userInfo: [String: String]) async throws {
        let manager = TWSFactory.new(with: TWSBasicConfiguration(id: "wrong"))
        manager.registerManager()
        
        #expect(await !TWSNotification().handleTWSPushNotification(userInfo))
    }
    
    @Test(
        "Tests parsing of correct notificaiton payload setup",
        arguments: [["type": "snippet_push", "path": "wrongFormat"]]
    )
    func notificationWrongPayloadParsingTest(userInfo: [String: String]) async throws {
        let manager = TWSFactory.new(with: TWSBasicConfiguration(id: "wrong"))
        manager.registerManager()
        
        #expect(await !TWSNotification().handleTWSPushNotification(userInfo))
    }
    
    @Test(
        "Tests parsing of correct notificaiton payload setup",
        arguments: [["type": "snippet_push", "path": "wrongFormat/test/test"]]
    )
    func notificationToLongPayloadParsingTest(userInfo: [String: String]) async throws {
        let manager = TWSFactory.new(with: TWSBasicConfiguration(id: "wrong"))
        manager.registerManager()
        
        #expect(await !TWSNotification().handleTWSPushNotification(userInfo))
    }
    
    @Test(
        "Tests parsing of correct notificaiton payload setup",
        arguments: [["type": "wrong_type", "path": "wrong/test/test"]]
    )
    func notificationInvalidPayloadTypeParsingTest(userInfo: [String: String]) async throws {
        let manager = TWSFactory.new(with: TWSBasicConfiguration(id: "wrong"))
        manager.registerManager()
        
        #expect(await !TWSNotification().handleTWSPushNotification(userInfo))
    }
    
    
}
