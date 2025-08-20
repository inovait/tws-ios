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


import Foundation
import WebKit

/// A manager class responsible for synchronizing and inspecting cookies
/// between the native `HTTPCookieStorage` and `WKWebView`'s `WKHTTPCookieStore`.
///
/// **Note:** This manager operates on the **default storages** provided by iOS:
/// - `HTTPCookieStorage.shared` for device-level cookies
/// - `WKWebsiteDataStore.default().httpCookieStore` for WebView cookies
///
/// All methods are executed on the `@MainActor` to ensure thread safety with UI-related components.
@MainActor
public class CookieManager {
    public init() {}
    
    /// Synchronizes cookies from the device's `HTTPCookieStorage` to the WebView's cookie store.
    public func syncDeviceCookiesToWebView() async {
        let deviceCookies = HTTPCookieStorage.shared.cookies ?? []
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        let webViewCookies = await cookieStore.allCookies()
        
        for deviceCookie in deviceCookies {
            if !webViewCookies.contains(where: { $0.name == deviceCookie.name && $0.domain == deviceCookie.domain }) {
                await cookieStore.setCookie(deviceCookie)
            }
        }
        
        for webViewCookie in webViewCookies {
            if !deviceCookies.contains(where: { $0.name == webViewCookie.name && $0.domain == webViewCookie.domain }) {
                await cookieStore.deleteCookie(webViewCookie)
            }
        }
        
        logger.info("[CookieManager] Device cookies synchronized to WebView.")
    }

    /// Synchronizes cookies from the WebView's `WKHTTPCookieStore` to the device's `HTTPCookieStorage`.
    public func syncWebViewCookiesToDevice() async {
        _ = await WKWebsiteDataStore.default().dataRecords(ofTypes: [WKWebsiteDataTypeCookies])
        
        let deviceCookies = HTTPCookieStorage.shared.cookies ?? []
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let webViewCookies = await cookieStore.allCookies()
        
        print("[svenk] number of cookies in webview: \(webViewCookies.count)")
        // Insert or update cookies from WebView to device storage
        for webViewCookie in webViewCookies {
            if !deviceCookies.contains(where: { $0.name == webViewCookie.name && $0.domain == webViewCookie.domain }) {
                HTTPCookieStorage.shared.setCookie(webViewCookie)
            }
        }
        
        // Delete cookies from device storage that are no longer in WebView
        for deviceCookie in deviceCookies {
            if !webViewCookies.contains(where: { $0.name == deviceCookie.name && $0.domain == deviceCookie.domain }) {
                HTTPCookieStorage.shared.deleteCookie(deviceCookie)
            }
        }
        
        logger.info("[CookieManager] WebView cookies synced to device.")
    }
    
    // MARK: - Utility
    
    
    /// Prints all cookies currently stored in the WebView's `WKHTTPCookieStore`.
    public func printWebViewCookies() async {
        logger.debug("[CookieManager] WebView Cookies:")
        await WKWebsiteDataStore.default().httpCookieStore.allCookies().forEach { cookie in
            print(cookie)
        }
    }
    
    /// Prints all cookies currently stored in the device's `HTTPCookieStorage`.
    public func printHTTPCookies() {
        logger.debug("[CookieManager] HTTPCookies:")
        HTTPCookieStorage.shared.cookies?.forEach { print($0) }
    }
    
    /// Prints a detailed comparison between device cookies and WebView cookies.
    public func printCookieDiff() async {
        let deviceCookies = HTTPCookieStorage.shared.cookies ?? []

        let webViewCookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        
        // Convert to dictionaries for easier comparison
        let deviceDict = Dictionary(uniqueKeysWithValues: deviceCookies.map { ($0.name, $0.value) })
        let webViewDict = Dictionary(uniqueKeysWithValues: webViewCookies.map { ($0.name, $0.value) })

        // Find cookies in device but not in webview
        let onlyInDevice = deviceDict.filter { webViewDict[$0.key] == nil }
        // Find cookies in webview but not in device
        let onlyInWebView = webViewDict.filter { deviceDict[$0.key] == nil }
        // Find cookies with different values
        let mismatched = deviceDict.filter { webViewDict[$0.key] != nil && webViewDict[$0.key] != $0.value }

        logger.debug("---- Cookie Diff ----")
        if onlyInDevice.isEmpty && onlyInWebView.isEmpty && mismatched.isEmpty {
            logger.debug("✅ Cookies are in sync")
        } else {
            if !onlyInDevice.isEmpty {
                logger.debug("📱 Only in device:")
                onlyInDevice.forEach { logger.debug("  \($0.key) = \($0.value.prefix(50))") }
            }
            if !onlyInWebView.isEmpty {
                logger.debug("🌐 Only in WKWebView:")
                onlyInWebView.forEach { logger.debug("  \($0.key) = \($0.value.prefix(50))") }
            }
            if !mismatched.isEmpty {
                logger.debug("⚠️ Mismatched values:")
                mismatched.forEach { logger.debug("  \($0.key): device=\($0.value.prefix(50)), webview=\(webViewDict[$0.key]!.prefix(50))") }
            }
        }
        logger.debug("---------------------")
    }
}


