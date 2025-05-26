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

extension View {

    /// Installs a loading view to be displayed while the ``TWSView`` is loading a webpage.
    ///
    /// - Parameter loadingView: A closure that returns the view to be displayed during the loading process.
    /// - Returns: A view that wraps the current view and includes the loading view.
    ///
    /// ## Usage of AnyView
    ///
    /// This method uses `AnyView` for flexibility, allowing different view hierarchies to be returned.
    /// The performance impact is minimal since the view being loaded is simple and lightweight.
    public func twsBind(
        loadingView: @Sendable @MainActor @escaping () -> AnyView
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: AttachLoadingView(loadingView: loadingView)
        )
    }

    /// Installs a preloading view to be displayed while the ``TWSView`` is preloading web resources.
    ///
    /// - Parameter preloadingView: A closure that returns the view to be displayed during the preloading process.
    /// - Returns: A view that wraps the current view and includes the preloading view.
    ///
    /// ## Usage of AnyView
    ///
    /// This method uses `AnyView` for flexibility, allowing different view hierarchies to be returned.
    /// The performance impact is minimal since the view being loaded is simple and lightweight.
    public func twsBind(
        preloadingView: @Sendable @MainActor @escaping () -> AnyView
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: AttachPreloadingView(preloadingView: preloadingView)
        )
    }

    /// Installs an error view to be displayed in case ``TWSView`` fails to load a webpage.
    ///
    /// - Parameter errorView: A closure that returns the view to be displayed for an error, exposes a reload action callback, that can be bound on a button
    /// - Returns: A view that wraps the current view and includes the error view.
    ///
    /// ## Usage of AnyView
    ///
    /// This method uses `AnyView` for flexibility, allowing different view hierarchies to be returned.
    /// The performance impact is minimal since the view being loaded is simple and lightweight.
    public func twsBind(
        errorView: @Sendable @MainActor @escaping (Error, _ reloadCallback: @escaping () -> Void) -> AnyView
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: AttachErrorView(errorView: errorView)
        )
    }
}

private struct AttachLoadingView: ViewModifier {

    let loadingView: @Sendable @MainActor () -> AnyView

    func body(content: Content) -> some View {
        content
            .environment(\.loadingView, loadingView)
    }
}

private struct AttachPreloadingView: ViewModifier {

    let preloadingView: @Sendable @MainActor () -> AnyView

    func body(content: Content) -> some View {
        content
            .environment(\.preloadingView, preloadingView)
    }
}

private struct AttachErrorView: ViewModifier {

    let errorView: @Sendable @MainActor (Error, @escaping () -> Void) -> AnyView

    func body(content: Content) -> some View {
        content
            .environment(\.errorView, errorView)
    }
}

extension EnvironmentValues {

    // Using AnyView here allows for flexibility in returning different view hierarchies while maintaining a consistent return type, with minimal performance impact in this simple loading view.
    @Entry var loadingView: @Sendable @MainActor () -> AnyView = {
        AnyView(_LoadingView())
    }

    // Using AnyView here allows for flexibility in returning different view hierarchies while maintaining a consistent return type, with minimal performance impact in this simple loading view.
    @Entry var preloadingView: @Sendable @MainActor () -> AnyView = {
        AnyView(_LoadingView())
    }

    // Using AnyView here allows for flexibility in returning different view hierarchies while maintaining a consistent return type, with minimal performance impact in this simple error view.
    @Entry var errorView: @Sendable @MainActor (Error, _ reloadCallback: @escaping () -> Void) -> AnyView = { error, reload in
        AnyView(
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)

                Text(error.localizedDescription)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    Button(action: reload) {
                        Text("Reload")
                    }
                }
            }
        )
    }
}

private struct _LoadingView: View {

    var body: some View {
        HStack {
            Spacer()

            ProgressView()
                .tint(.white)
                .padding(10)
                .background(Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer()
        }
        .padding()
    }
}
