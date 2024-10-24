//
//  View+TWSPlaceholders.swift
//  TWSKit
//
//  Created by Miha Hozjan on 24. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

public extension View {

    /// Installs a loading view to be displayed while the ``TWSView`` is loading a webpage.
    ///
    /// - Parameter loadingView: A closure that returns the view to be displayed during the loading process.
    /// - Returns: A view that wraps the current view and includes the loading view.
    ///
    /// ## Usage of ``AnyView``
    ///
    /// This method uses `AnyView` for flexibility, allowing different view hierarchies to be returned.
    /// The performance impact is minimal since the view being loaded is simple and lightweight.
    func twsBind(
        loadingView: @Sendable @MainActor @escaping () -> AnyView
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: AttachLoadingView(loadingView: loadingView)
        )
    }

    /// Installs an error view to be displayed in case ``TWSView`` fails to load a webpage.
    ///
    /// - Parameter errorView: A closure that returns the view to be displayed for an error
    /// - Returns: A view that wraps the current view and includes the error view.
    ///
    /// ## Usage of ``AnyView``
    ///
    /// This method uses `AnyView` for flexibility, allowing different view hierarchies to be returned.
    /// The performance impact is minimal since the view being loaded is simple and lightweight.
    func twsBind(
        errorView: @Sendable @MainActor @escaping (Error) -> AnyView
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

private struct AttachErrorView: ViewModifier {

    let errorView: @Sendable @MainActor (Error) -> AnyView

    func body(content: Content) -> some View {
        content
            .environment(\.errorView, errorView)
    }
}

extension EnvironmentValues {

    // Using AnyView here allows for flexibility in returning different view hierarchies while maintaining a consistent return type, with minimal performance impact in this simple loading view.
    @Entry var loadingView: @Sendable @MainActor () -> AnyView = {
        AnyView(
            HStack {
                Spacer()

                ProgressView(label: { Text("Loading...") })

                Spacer()
            }
            .padding()
        )
    }

    // Using AnyView here allows for flexibility in returning different view hierarchies while maintaining a consistent return type, with minimal performance impact in this simple error view.
    @Entry var errorView: @Sendable @MainActor (Error) -> AnyView = { error in
        AnyView(
            HStack {
                Spacer()

                Text("Error: \(error.localizedDescription)")
                    .padding()

                Spacer()
            }
            .padding()
        )
    }
}
