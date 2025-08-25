///
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
import Foundation
import OSLog
import WebKit
@testable import TWSCookieManager

@MainActor
struct TWSCookieManagerTest {
    private func makeCookie(name: String, value: String, domain: String = "example.com") -> HTTPCookie {
        return HTTPCookie(properties: [
            .version: "1",
            .domain: domain,
            .path: "/",
            .name: name,
            .value: "value-\(value)",
            .secure: "FALSE"
        ])!
    }
    
    @Test(
        "Tests syncing of WebView cookies to device"
    )
    func syncWebViewCookiesToDeviceTest() async throws {
        
        let deviceStorage: HTTPCookieStorage = .sharedCookieStorage(forGroupContainerIdentifier: "twsCookieManagerTest1")
        let webViewStore: WKWebsiteDataStore = .nonPersistent()
        let cookieManager: TWSCookieManager = .init(deviceStorage: deviceStorage, webViewStore: webViewStore)
        
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "WebViewCookie1", value: "TestCookie1"))
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "WebViewCookie2", value: "TestCookie2"))
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "WebViewCookie3", value: "TestCookie3"))
        deviceStorage.setCookie(makeCookie(name: "NativeCookie", value: "TestCookie1"))
        
        await cookieManager.syncWebViewCookiesToDevice()
        let deviceCookies = deviceStorage.cookies ?? []
        let webViewCookies = await webViewStore.httpCookieStore.allCookies()
        webViewCookies.forEach { cookie in
            #expect(deviceCookies.contains(cookie))
        }
        
        #expect(deviceCookies.count == webViewCookies.count)
    }
    
    @Test("Tests syncing of device cookies to WebView")
    func syncDeviceCookiesToWebViewTest() async throws {
        let deviceStorage: HTTPCookieStorage = .sharedCookieStorage(forGroupContainerIdentifier: "twsCookieManagerTest2")
        let webViewStore: WKWebsiteDataStore = .nonPersistent()
        let cookieManager: TWSCookieManager = .init(deviceStorage: deviceStorage, webViewStore: webViewStore)

        deviceStorage.setCookie(makeCookie(name: "NativeCookie1", value: "TestCookie1"))
        deviceStorage.setCookie(makeCookie(name: "NativeCookie2", value: "TestCookie2"))
        deviceStorage.setCookie(makeCookie(name: "NativeCookie3", value: "TestCookie3"))
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "WebViewCookie", value: "TestCookie1"))
        
        await cookieManager.syncDeviceCookiesToWebView()
        
        let deviceCookies = deviceStorage.cookies ?? []
        let webViewCookies = await webViewStore.httpCookieStore.allCookies()
        
        deviceCookies.forEach { cookie in
            #expect(webViewCookies.contains(cookie))
        }
        
        #expect(deviceCookies.count == webViewCookies.count)
    }
    
    @Test("Tests whether existing cookies get overriden when syncing from WebView to device")
    func overrideDeviceCookieOnSyncTest() async throws {
        let deviceStorage: HTTPCookieStorage = .sharedCookieStorage(forGroupContainerIdentifier: "twsCookieManagerTest3")
        let webViewStore: WKWebsiteDataStore = .nonPersistent()
        let cookieManager: TWSCookieManager = .init(deviceStorage: deviceStorage, webViewStore: webViewStore)

        deviceStorage.setCookie(makeCookie(name: "ExistingCookie", value: "OriginalValue"))
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "ExistingCookie", value: "OverridenValue"))
        
        await cookieManager.syncWebViewCookiesToDevice()
        let deviceCookies = deviceStorage.cookies ?? []
        let webViewCookies = await webViewStore.httpCookieStore.allCookies()
        
        webViewCookies.forEach { cookie in
            #expect(deviceCookies.contains(cookie))
        }
        
        let resultingCookie = deviceCookies.first(where: { $0.name == "ExistingCookie" })
        #expect(resultingCookie != nil && resultingCookie!.value == "value-OverridenValue")
        
    }
    
    @Test("Tests whether existing cookies get overriden when syncing from device to WebView")
    func overrideWebViewCookieOnSyncTest() async throws {
        let deviceStorage: HTTPCookieStorage = .sharedCookieStorage(forGroupContainerIdentifier: "twsCookieManagerTest4")
        let webViewStore: WKWebsiteDataStore = .nonPersistent()
        let cookieManager: TWSCookieManager = .init(deviceStorage: deviceStorage, webViewStore: webViewStore)

        deviceStorage.setCookie(makeCookie(name: "ExistingCookie", value: "OverridenValue"))
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "ExistingCookie", value: "OriginalValue"))
        
        await cookieManager.syncDeviceCookiesToWebView()
        let deviceCookies = deviceStorage.cookies ?? []
        let webViewCookies = await webViewStore.httpCookieStore.allCookies()
        
        webViewCookies.forEach { cookie in
            #expect(deviceCookies.contains(cookie))
        }
        
        let resultingCookie = webViewCookies.first(where: { $0.name == "ExistingCookie" })
        #expect(resultingCookie != nil && resultingCookie!.value == "value-OverridenValue")
    }
}
