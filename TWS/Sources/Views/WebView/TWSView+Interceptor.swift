//
//  TWSView+Interceptor.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 14. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
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

    func handleUrl(_ url: URL) -> Bool
}
