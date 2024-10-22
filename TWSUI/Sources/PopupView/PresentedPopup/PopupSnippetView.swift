//
//  PopupSnippetView.swift
//  TWSAPI
//
//  Created by Luka Kit on 23. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import SwiftUI
import TWSKit

struct PopupSnippetView: View {

    let snippet: TWSSnippet
    let manager: TWSManager
    @State private var loadingState: TWSLoadingState = .idle

    var body: some View {
        TWSView(
            snippet: snippet,
            displayID: "popup-\(snippet.id.uuidString)",
            canGoBack: .constant(false),
            canGoForward: .constant(false),
            loadingState: $loadingState,
            loadingView: {},
            errorView: { _ in
            }
        )
    }
}
