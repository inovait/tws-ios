//
//  TWSViewInfo.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 22. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

@Observable
public final class TWSViewInfo {

    /// Once the snippet is loaded, it's title will be set in this variable
    public var title: String = ""

    /// A Boolean value that indicates whether there is a valid back item in the back-forward list on a webpage
    public var canGoBack: Bool

    /// A Boolean value that indicates whether there is a valid forward item in the back-forward list on a webpage
    public var canGoForward: Bool

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
        self.canGoBack = false
        self.canGoForward = false
        self.loadingState = loadingState
    }
}
