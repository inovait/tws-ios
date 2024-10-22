//
//  View+TWSActions.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 22. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

public extension View {

    func twsOnDownloadCompleted(
        action: @Sendable @escaping @MainActor (TWSDownloadState) -> Void
    ) -> some View {
        self
            .environment(\.onDownloadCompleted, action)
    }
}

extension EnvironmentValues {

    @Entry var onDownloadCompleted: (@Sendable @MainActor (TWSDownloadState) -> Void)?
}
