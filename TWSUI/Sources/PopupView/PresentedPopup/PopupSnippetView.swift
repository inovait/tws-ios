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
    @Environment(TWSDefaultLocationServicesManager.self) private var locationHandler
    @Environment(TWSCameraMicrophoneServiceManager.self) private var cameraMicrophoneHandler

    var body: some View {
        TWSView(
            snippet: snippet,
            locationServicesBridge: locationHandler,
            cameraMicrophoneServicesBridge: cameraMicrophoneHandler,
            using: manager,
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
