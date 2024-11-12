//
//  View+EnableTWS.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 22. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

extension View {

    public func twsEnable(
        using manager: TWSManager
    ) -> some View {
        self
            .environment(manager)
            .environment(\.twsPresenter, LivePresenter(manager: manager))
            .task {
                manager.run()
            }
    }

    public func twsEnable(
        configuration: TWSConfiguration
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: _TWSPlaceholder(
                manager: TWSFactory.new(with: configuration)
            )
        )
    }

    public func twsEnable(
        bundle: TWSSharedSnippetBundle
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: _TWSPlaceholder(
                manager: TWSFactory.new(with: bundle)
            )
        )
    }
}

private struct _TWSPlaceholder: ViewModifier {

    @State private var manager: TWSManager

    init(manager: TWSManager) {
        self._manager = .init(initialValue: manager)
    }

    func body(content: Content) -> some View {
        content
            .twsEnable(using: manager)
    }
}
