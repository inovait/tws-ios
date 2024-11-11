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
    @State private var info = TWSViewInfo()

    var body: some View {
        @Bindable var info = info

        TWSView(
            snippet: snippet,
            info: $info
        )
    }
}
