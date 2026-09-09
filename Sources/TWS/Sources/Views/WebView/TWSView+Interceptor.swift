//
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

import SwiftUI

/// # TWSViewInterceptor
///
/// A protocol that provides an interface for intercepting and handling URL navigation within a ``TWSView``.
///
/// This protocol enables custom navigation behavior by allowing you to intercept URLs before they are loaded in the web view. Implementing this protocol allows you to decide whether a specific URL should be loaded by the web view or handled natively within your application.
///
/// ## Key Features
/// - Prevent the web view from loading specific URLs.
/// - Handle navigation natively for custom schemes, domains, or specific paths.
/// - Enhance user experience by integrating native features seamlessly.
///
/// > Note: Returning `true` from the `handleIntercept(_:)` method will prevent the web view from loading the intercepted URL.
///
/// ## Usage
///
/// You can provide a custom implementation of this protocol and inject it into the ``TWSView`` using the appropriate configuration or environment modifier.
///
/// ### Example
///
/// ```swift
/// final class CustomInterceptor: TWSViewInterceptor {
///     func handleIntercept(_ url: TWSIntercepted) -> Bool {
///         if url.host == "native.example.com" {
///             // Handle URL natively
///             print("Intercepted and handled natively: \(url)")
///             return true
///         }
///         // Allow other URLs to load in the web view
///         return false
///     }
/// }
///
/// struct ContentView: View {
///     var body: some View {
///         TWSView()
///             .twsBind(interceptor: CustomInterceptor())
///     }
/// }
/// ```
///
/// This setup enables fine-grained control over URL navigation behavior within the ``TWSView``.
@MainActor
public protocol TWSViewInterceptor: AnyObject, Sendable {

    /// Intercepts the URL, before the web view loads it.
    ///
    /// - Parameters:
    ///   - url: A URL or path that was intercepted.
    /// - Returns: A boolean where true indicates that this url was handled, false indicates that web view should load the URL normally.
    ///
    ///  Note: URL is returned for content loads, path is returned if you handle SPA navigation with JavaScript bridge sending
    ///  window.webkit.messageHandlers.intercept.postMessage(path) from JavaScript
    ///
    ///  > Important: This is called while the web view is still waiting for a navigation policy decision.
    ///  Do not start a navigation on that web view from here - including ``TWSViewNavigator/reload()``,
    ///  ``TWSViewNavigator/load(url:behaveAsSpa:)`` or state changes that cause SwiftUI to reload it.
    ///  Hop to the next main-runloop turn first.
    func handleIntercept(_ intercept: TWSIntercepted) -> Bool
}

public enum TWSIntercepted {

    /// An SPA navigation reported by the JavaScript bridge.
    case path(String)

    /// A content load the web view is about to perform, and what caused it.
    ///
    /// Switch on `navigationType` to treat kinds of navigation differently - most usefully
    /// ``TWSNavigationType/reload``, which lets you react to a page reloading itself.
    case url(URL, navigationType: TWSNavigationType)
}

/// What caused a navigation the web view is about to perform.
///
/// Mirrors `WKNavigationType` so that interceptors do not have to import WebKit.
public enum TWSNavigationType: Equatable, Sendable {

    /// The user activated a link.
    case linkActivated

    /// A form was submitted.
    case formSubmitted

    /// The user went back or forward through the session history.
    case backForward

    /// The page is reloading itself, e.g. via `location.reload()`.
    ///
    /// Returning `true` for a reload hands it to your app: TWS cancels it and does *not* run its own
    /// reload, so the snippet's dynamic resources are not re-injected and the loading state does not
    /// advance - drive the reload yourself if you take it over. Returning `false` leaves TWS's default
    /// reload handling untouched.
    ///
    /// > Note: Only page-initiated reloads reach the interceptor. Reloads your app starts through
    /// ``TWSViewNavigator/reload()``, and pull-to-refresh, bypass the navigation policy delegate
    /// entirely.
    case reload

    /// A form was resubmitted, e.g. by going back to a page that was the result of a form submission.
    case formResubmitted

    /// Navigation is taking place for some other reason.
    case other
}
