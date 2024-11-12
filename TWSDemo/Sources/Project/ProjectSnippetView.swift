//
//  ProjectSnippetView.swift
//  TWS
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWS

struct ProjectSnippetView: View {

    @State private var info: TWSViewInfo = .init()
    let snippet: TWSSnippet

    @Environment(\.dismiss) var dismiss

    var body: some View {
        @Bindable var info = info

        return VStack {
            HStack {
                Button(
                    action: {
                        if let url = URL(string: "https://manage.thewebsnippet.dev/snippets-list") {
                            UIApplication.shared.open(url)
                        }
                    },
                    label: {
                        Text("TWS - \(info.title)")
                            .lineLimit(1)
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
                info: $info
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
