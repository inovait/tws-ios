//
//  View+TWSPresenter.swift
//  TWS
//
//  Created by Miha Hozjan on 11. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

extension EnvironmentValues {

    @Entry var presenter: TWSPresenter = NoopPresenter()
}

extension View {

    public func twsLocal(_ override: Bool = true) -> some View {
        ModifiedContent(
            content: self,
            modifier: PresenterViewModifer(overrideToLocal: override)
        )
    }
}

private struct PresenterViewModifer: ViewModifier {

    let overrideToLocal: Bool

    func body(content: Content) -> some View {
        if overrideToLocal {
            content
                .environment(\.presenter, NoopPresenter())
        } else {
            content
        }
    }
}
