//
//  TWSViewInfo.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 22. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

@Observable
public final class TWSViewState {

    /// Once the snippet is loaded, it's title will be set in this variable
    public var title: String = ""

    /// An instance of ``TWSLoadingState`` that tells you the state of the snippet
    public var loadingState: TWSLoadingState

    /// Initialiezes a class that ``TWSView`` uses to store information in
    /// - Parameter title: default title of the page
    /// - Parameter loadingState: the initial state for the loading state
    public init(
        title: String = "",
        loadingState: TWSLoadingState = .idle
    ) {
        self.title = title
        self.loadingState = loadingState
    }
}
