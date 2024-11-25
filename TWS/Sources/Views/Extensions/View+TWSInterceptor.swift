//
//  View+TWSInterceptor.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 13. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

extension EnvironmentValues {

    @Entry var interceptor: TWSViewInterceptor?
}

extension View {

    /// A SwiftUI helper method for binding a custom ``TWSViewInterceptor`` to the environment.
    ///
    /// This method allows you to provide a custom implementation of the ``TWSViewInterceptor`` protocol and inject it into the environment, enabling full control over URL navigation within a ``TWSView``.
    ///
    /// - Parameter interceptor: An implementation of ``TWSViewInterceptor`` to handle URL navigation.
    /// - Returns: A view with the custom interceptor injected into its environment.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         TWSView()
    ///             .twsBind(interceptor: MyCustomInterceptor())
    ///     }
    /// }
    /// ```
    ///
    /// This setup allows the provided interceptor to intercept URLs navigated within the ``TWSView``, enabling custom handling or preventing the web view from loading specific content.
    public func twsBind(
        interceptor: TWSViewInterceptor
    ) -> some View {
        self
            .environment(\.interceptor, interceptor)
    }
}
