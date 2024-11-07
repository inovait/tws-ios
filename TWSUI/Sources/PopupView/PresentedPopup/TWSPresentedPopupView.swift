//
//  TWSPopupView.swift
//  TWSUI
//
//  Created by Luka Kit on 24. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSModels
import TWSKit

struct TWSPresentedPopupView: View {

    @State var snippet: TWSSnippet
    let manager: TWSManager
    let onClose: ((TWSSnippet) -> Void)

    public init(manager: TWSManager, snippet: TWSSnippet, onClose: @escaping ((TWSSnippet) -> Void)) {
        self.snippet = snippet
        self.onClose = onClose
        self.manager = manager
    }

    public var body: some View {
        ZStack {
            PopupSnippetView(snippet: snippet, manager: manager)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onClose(snippet)
                    }, label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .padding()
                    })
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
                    .padding()
                }
                Spacer()
            }
        }
    }
}
