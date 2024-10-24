//
//  View+TWSPlaceholders.swift
//  TWSKit
//
//  Created by Miha Hozjan on 24. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

public extension View {

    func tws(
        loadingView: @Sendable @MainActor @escaping () -> AnyView
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: AttachLoadingView(loadingView: loadingView)
        )
    }

    func tws(
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
