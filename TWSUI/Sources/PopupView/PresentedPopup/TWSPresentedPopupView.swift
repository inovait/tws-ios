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

    @State var popupViewModel: TWSPresentedPopupViewModel
    @State var snippet: TWSSnippet
    let onClose: ((TWSSnippet) -> Void)

    public init(manager: TWSManager, snippet: TWSSnippet, onClose:@escaping ((TWSSnippet) -> Void)) {
        self.snippet = snippet
        self.onClose = onClose
        self.popupViewModel = TWSPresentedPopupViewModel(manager: manager)
    }

    public var body: some View {
        ZStack {
            PopupSnippetView(snippet: snippet, manager: popupViewModel.manager)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        popupViewModel.onSnippetClosed(snippet: snippet)
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
