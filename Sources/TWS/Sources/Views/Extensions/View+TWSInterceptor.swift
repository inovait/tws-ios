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

extension EnvironmentValues {
    @Entry var interceptor: TWSViewInterceptor = NoOpInterceptor()
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
