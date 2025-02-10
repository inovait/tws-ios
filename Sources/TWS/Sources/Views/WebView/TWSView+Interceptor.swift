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
/// > Note: Returning `true` from the `handleUrl(_:)` method will prevent the web view from loading the intercepted URL.
///
/// ## Usage
///
/// You can provide a custom implementation of this protocol and inject it into the ``TWSView`` using the appropriate configuration or environment modifier.
///
/// ### Example
///
/// ```swift
/// final class CustomInterceptor: TWSViewInterceptor {
///     func handleUrl(_ url: URL) -> Bool {
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
    ///   - url: A URL that was intercepted.
    /// - Returns: True indicates that this url was handled, false indicates that web view should load the URL normally.
    func handleUrl(_ url: URL) -> Bool
}
