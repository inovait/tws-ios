//
//  ProjectSnippetView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

struct ProjectSnippetView: View {

    let snippet: TWSSnippet
    let manager: TWSManager
    @State private var loadingState: TWSLoadingState = .idle
    @State private var pageTitle: String = ""

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Button(
                    action: {
                        if let url = URL(string: "https://manage.thewebsnippet.dev/snippets-list") {
                            UIApplication.shared.open(url)
                        }
                    },
                    label: {
                        Text("TWS - \($pageTitle.wrappedValue)")
                            .foregroundColor(.black)
                    }
                )

                Spacer()

                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22))
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.black)
                })
            }
            .padding()
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.black),

                alignment: .bottom
            )

            TWSView(
                snippet: snippet,
                using: manager,
                displayID: "\(manager.id.hashValue)",
                canGoBack: .constant(false),
                canGoForward: .constant(false),
                loadingState: $loadingState,
                pageTitle: $pageTitle,
                loadingView: { WebViewLoadingView() },
                errorView: { WebViewErrorView(error: $0) }
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
