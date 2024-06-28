//
//  WebView+Helpers.swift
//  TWSAPI
//
//  Created by Luka Kit on 28. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

struct WebViewLoadingView: View {

    var body: some View {
        HStack {
            Spacer()

            ProgressView(label: { Text("Loading...") })

            Spacer()
        }
        .padding()
    }
}

struct WebViewErrorView: View {
    let error: Error

    var body: some View {
        HStack {
            Spacer()

            Text("Error: \(error.localizedDescription)")
                .padding()

            Spacer()
        }
        .padding()
    }
}
