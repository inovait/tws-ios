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
    private func makeCookie(name: String, domain: String = "example.com") -> HTTPCookie {
        return HTTPCookie(properties: [
            .version: "1",
            .domain: domain,
            .path: "/",
            .name: name,
            .value: "value-\(name)",
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
        
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "WebViewCookie1"))
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "WebViewCookie2"))
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "WebViewCookie3"))
        deviceStorage.setCookie(makeCookie(name: "NativeCookie"))
        
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

        deviceStorage.setCookie(makeCookie(name: "NativeCookie1"))
        deviceStorage.setCookie(makeCookie(name: "NativeCookie2"))
        deviceStorage.setCookie(makeCookie(name: "NativeCookie3"))
        await webViewStore.httpCookieStore.setCookie(makeCookie(name: "WebViewCookie"))
        
        await cookieManager.syncDeviceCookiesToWebView()
        
        let deviceCookies = deviceStorage.cookies ?? []
        let webViewCookies = await webViewStore.httpCookieStore.allCookies()
        
        deviceCookies.forEach { cookie in
            #expect(webViewCookies.contains(cookie))
        }
        
        #expect(deviceCookies.count == webViewCookies.count)
    }
}
