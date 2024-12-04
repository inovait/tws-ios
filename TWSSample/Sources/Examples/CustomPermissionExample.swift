//
//  CustomPermissionExample.swift
//  TheWebSnippet
//
//  Created by Miha Hozjan on 2. 12. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWS

struct CustomPermissionExample: View {

    @Environment(TWSManager.self) var tws
    @State private var alertMsg = ""
    @State private var showAlert = false

    var body: some View {
        if let snippet = tws.snippets().first(where: { $0.id == "permissions" }) {
            TWSView(snippet: snippet)
                .twsOnDownloadCompleted { state in
                    switch state {
                    case let .completed(info):
                        var log = "Download completed successfully. File name:"
                        log += " \(info.downloadedFilename)"
                        log += ", location: \(info.downloadedLocation)"
                        alertMsg = log
                        showAlert = true

                    case let .failed(error):
                        alertMsg = error.localizedDescription
                        showAlert = true

                    @unknown default:
                        break
                    }
                }
                .alert(alertMsg, isPresented: $showAlert, actions: {})
        }
    }
}
